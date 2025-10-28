// lib/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:gamefymobile/settings_screen.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../config/app_colors.dart';
import '../config/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../main.dart';
import 'user_level_avatar.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Usuario? usuario;
  final List<Notificacao> notificacoes;
  final List<DesafioPendente> desafios;
  final List<Conquista> conquistas;
  final VoidCallback onDataReload;
  final bool showBackButton;
  // Callback opcional para interceptar ação do botão voltar
  final Future<bool> Function()? onBackRequest;

  const CustomAppBar({
    super.key,
    required this.usuario,
    required this.notificacoes,
    required this.desafios,
    required this.conquistas,
    required this.onDataReload,
    this.showBackButton = false,
    this.onBackRequest,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late List<Notificacao> _localNotificacoes;
  final int _pageSize = 10;
  final GlobalKey<PopupMenuButtonState<String>> _userMenuKey =
      GlobalKey<PopupMenuButtonState<String>>();

  @override
  void initState() {
    super.initState();
    _localNotificacoes = widget.notificacoes.map((n) => n).toList();
  }

  @override
  void didUpdateWidget(covariant CustomAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificacoes != widget.notificacoes) {
      _localNotificacoes = widget.notificacoes.map((n) => n).toList();
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'sair') {
      AuthService().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    } else if (value == 'tema') {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.toggleTheme();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(themeProvider.isDarkMode
              ? 'Tema Escuro Ativado'
              : 'Tema Claro Ativado'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (value == 'config') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) => widget.onDataReload());
    }
  }

  Future<void> _showNotificationDetails(
      BuildContext context, Notificacao notificacao) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.fundoCard,
          title: Text('Notificação',
              style: TextStyle(color: themeProvider.textoTexto)),
          content: Text(notificacao.mensagem,
              style: TextStyle(color: themeProvider.textoTexto)),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar',
                  style: TextStyle(color: AppColors.verdeLima)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markOneAsReadAndShow(
      BuildContext context, Notificacao n) async {
    try {
      await ApiService().marcarNotificacaoComoLida(n.id);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }

    final idx = _localNotificacoes.indexWhere((e) => e.id == n.id);
    if (idx != -1) {
      _localNotificacoes[idx] = Notificacao(
        id: _localNotificacoes[idx].id,
        mensagem: _localNotificacoes[idx].mensagem,
        tipo: _localNotificacoes[idx].tipo,
        lida: true,
      );
      if (mounted) setState(() {});
    }

    if (!context.mounted) return;
    _showNotificationDetails(context, n);
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService().marcarTodasNotificacoesComoLidas();
    } catch (e) {
      debugPrint('Erro ao marcar todas notificações como lidas: $e');
    }
    _localNotificacoes = _localNotificacoes
        .map((n) => Notificacao(
            id: n.id, mensagem: n.mensagem, tipo: n.tipo, lida: true))
        .toList();
    if (!context.mounted) return;
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Todas as notificações marcadas como lidas')),
      );
    }
  }

  int _unreadCount() {
    return _localNotificacoes.where((n) => !n.lida).length;
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = _unreadCount();

    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      toolbarHeight: 60,
      leading: widget.showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Provider.of<ThemeProvider>(context).textoTexto),
              onPressed: () async {
                // Se houver um interceptador, respeitar o retorno dele
                if (widget.onBackRequest != null) {
                  final shouldPop = await widget.onBackRequest!();
                  if (shouldPop && context.mounted) {
                    // Usar maybePop para respeitar PopScope/WillPopScope quando existir
                    Navigator.of(context).maybePop();
                  }
                } else {
                  // Comportamento padrão
                  Navigator.of(context).maybePop();
                }
              },
            )
          : null,
      automaticallyImplyLeading: false,
      titleSpacing: widget.showBackButton ? 0 : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNotificationButton(context, naoLidas),
          const SizedBox(width: 16),
          _buildChallengesAchievementsButton(context),
        ],
      ),
      actions: [
        if (widget.usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserMenuButton(context, widget.usuario!),
          ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, int naoLidas) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final preview = _localNotificacoes.take(_pageSize).toList();
    final hasMore = _localNotificacoes.length > _pageSize;

    return PopupMenuButton<dynamic>(
      onSelected: (value) async {
        if (value == 'marcar_todas') {
          await _markAllAsRead();
        } else if (value == 'ver_mais') {
          _showAllNotificationsModal(context);
        } else if (value is Notificacao) {
          await _markOneAsReadAndShow(context, value);
        }
      },
      color: themeProvider.fundoCard,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.mail, color: AppColors.verdeLima, size: 30),
          if (naoLidas > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.roxoHeader, width: 2)),
                child: Text('$naoLidas',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<dynamic>>[];

        items.add(
          PopupMenuItem(
            value: 'marcar_todas',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Marcar todas como lidas',
                    style: TextStyle(color: themeProvider.textoTexto)),
                Icon(Icons.done_all, color: AppColors.verdeLima),
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        if (preview.isEmpty) {
          items.add(PopupMenuItem(
              enabled: false,
              child: Text("Nenhuma notificação",
                  style: TextStyle(color: themeProvider.textoCinza))));
        } else {
          for (final n in preview) {
            items.add(PopupMenuItem<Notificacao>(
              value: n,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  n.lida
                      ? Icons.check_circle_outline
                      : Icons.circle_notifications,
                  color: n.lida
                      ? themeProvider.textoCinza
                      : AppColors.amareloClaro,
                ),
                title: Text(n.mensagem,
                    style: TextStyle(
                        color: n.lida
                            ? themeProvider.textoCinza
                            : themeProvider.textoTexto)),
              ),
            ));
          }
        }

        if (hasMore) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem(
              value: 'ver_mais',
              child: Text('Ver mais...',
                  style: TextStyle(color: AppColors.verdeLima))));
        }

        return items;
      },
    );
  }

  Widget _buildChallengesAchievementsButton(BuildContext context) {
    final diarios = widget.desafios
        .where((d) => d.tipo.trim().toLowerCase() == 'diário')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // A lista de conquistas contém apenas as desbloqueadas pelo usuário
    final conquistasDesbloqueadas = widget.conquistas
      ..sort((a, b) => a.nome.compareTo(b.nome));

    final themeProvider = Provider.of<ThemeProvider>(context);
    return PopupMenuButton<int>(
        color: themeProvider.fundoCard,
        icon: const Icon(Icons.emoji_events,
            color: AppColors.verdeLima, size: 30),
        offset: const Offset(0, 50),
        itemBuilder: (context) => [
              PopupMenuItem<int>(
                  enabled: false,
                  child: SizedBox(
                      width: 320,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- SEÇÃO DE DESAFIOS (Inalterada) ---
                            Text("Desafios diários",
                                style: TextStyle(
                                    color: themeProvider.textoTexto,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 8),
                            if (diarios.isEmpty)
                              Text("Nenhum desafio diário",
                                  style: TextStyle(
                                      color: themeProvider.textoCinza))
                            else
                              Column(
                                  children: diarios.map((d) {
                                double progresso = d.progresso / max(1, d.meta);
                                return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: d.completado
                                            ? AppColors.roxoProfundo
                                            : AppColors.roxoMedio,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(children: [
                                      d.completado
                                          ? const Icon(Icons.check_circle,
                                              color: AppColors.verdeLima,
                                              size: 20)
                                          : const Icon(
                                              Icons.emoji_events_outlined,
                                              color: AppColors.amareloClaro,
                                              size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(d.nome,
                                                style: TextStyle(
                                                    color: d.completado
                                                        ? themeProvider
                                                            .textoCinza
                                                        : themeProvider
                                                            .textoTexto,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                                value: progresso,
                                                backgroundColor:
                                                    AppColors.roxoProfundo,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                            Color>(
                                                        AppColors.amareloClaro),
                                                minHeight: 6,
                                                borderRadius:
                                                    BorderRadius.circular(3))
                                          ])),
                                      const SizedBox(width: 8),
                                      Text("${d.progresso}/${d.meta}",
                                          style: TextStyle(
                                              color: d.completado
                                                  ? themeProvider.textoCinza
                                                  : themeProvider.textoTexto)),
                                      const SizedBox(width: 8),
                                      Text("${d.xp}xp",
                                          style: const TextStyle(
                                              color: AppColors.amareloClaro,
                                              fontWeight: FontWeight.bold))
                                    ]));
                              }).toList()),

                            const SizedBox(height: 12),
                            const Divider(color: AppColors.roxoProfundo),
                            const SizedBox(height: 8),

                            // --- NOVA SEÇÃO DE CONQUISTAS ---
                            Text("Conquistas Desbloqueadas",
                                style: TextStyle(
                                    color: themeProvider.textoTexto,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 8),
                            if (conquistasDesbloqueadas.isEmpty)
                              Text("Nenhuma conquista desbloqueada",
                                  style: TextStyle(
                                      color: themeProvider.textoCinza))
                            else
                              // Exibição em formato de lista
                              Column(
                                children: conquistasDesbloqueadas.map((c) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        c.imagemUrl != null &&
                                                c.imagemUrl!.isNotEmpty
                                            ? Image.network(
                                                c.imagemUrl!,
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.emoji_events,
                                                        size: 30),
                                              )
                                            : Image.asset(
                                                "assets/conquistas/${c.imagem}",
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.emoji_events,
                                                        size: 30),
                                              ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            c.nome,
                                            style: TextStyle(
                                                color:
                                                    themeProvider.textoTexto),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                          ])))
            ]);
  }

  Widget _buildUserMenuButton(BuildContext context, Usuario user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _userMenuKey.currentState?.showButtonMenu(),
      child: PopupMenuButton<String>(
        key: _userMenuKey,
        onSelected: (value) => _handleMenuSelection(context, value),
        color: themeProvider.fundoDropDown,
        offset: const Offset(0, 50),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(text: 'Mudar Tema', value: 'tema'),
          _buildPopupMenuItem(text: 'Sair', value: 'sair'),
        ],
        child: UserLevelAvatar(user: user, radius: 24),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      {required String text, required String value}) {
    // Importante: usar listen: false aqui porque este método pode ser chamado fora do ciclo de build
    // (por exemplo, quando o PopupMenu é aberto via gesto), o que quebra o assert do provider.
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return PopupMenuItem<String>(
        value: value,
        child: Container(
            decoration: BoxDecoration(
                color: themeProvider.botaoDropDown,
                borderRadius: BorderRadius.circular(5)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        fontFamily: 'Jersey 10',
                        color: themeProvider.textoTexto)))));
  }

  void _showAllNotificationsModal(BuildContext context) {
    // Importante: usar listen: false fora do ciclo de build para evitar o assert do provider
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.fundoCard,
      isScrollControlled: true,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        int dialogLimit = _pageSize;
        return StatefulBuilder(builder: (context, setStateModal) {
          final items = _localNotificacoes.take(dialogLimit).toList();
          final hasMore = _localNotificacoes.length > dialogLimit;

          return FractionallySizedBox(
            heightFactor: 0.6,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              size: 20, color: themeProvider.textoTexto),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Notificações',
                          style: TextStyle(
                              color: themeProvider.textoTexto,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          '${_localNotificacoes.length}',
                          style: TextStyle(color: themeProvider.textoCinza),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: AppColors.roxoProfundo, height: 1),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppColors.roxoProfundo),
                        itemBuilder: (context, i) {
                          final n = items[i];
                          return ListTile(
                            tileColor: n.lida
                                ? themeProvider.fundoCard
                                : AppColors.roxoMedio,
                            onTap: () async {
                              await _markOneAsReadAndShow(context, n);
                              setStateModal(() {});
                            },
                            leading: Icon(
                              n.lida
                                  ? Icons.check_circle_outline
                                  : Icons.circle_notifications,
                              color: n.lida
                                  ? themeProvider.textoCinza
                                  : AppColors.amareloClaro,
                            ),
                            title: Text(
                              n.mensagem,
                              style: TextStyle(
                                  color: n.lida
                                      ? themeProvider.textoCinza
                                      : themeProvider.textoTexto),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                          );
                        },
                      ),
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.roxoClaro),
                            onPressed: () {
                              dialogLimit += _pageSize;
                              setStateModal(() {});
                            },
                            child: const Text(
                              'Carregar mais 10',
                              style: TextStyle(
                                color: AppColors.branco,
                                fontFamily: 'Jersey 10',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}
