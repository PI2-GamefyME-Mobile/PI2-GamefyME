import 'package:flutter/material.dart';
import 'package:gamefymobile/settings_screen.dart';
import 'dart:math';

import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../main.dart';
import 'user_level_avatar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Usuario? usuario;
  final List<Notificacao> notificacoes;
  final List<DesafioPendente> desafios;
  final List<Conquista> conquistas;
  final VoidCallback onDataReload;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.usuario,
    required this.notificacoes,
    required this.desafios,
    required this.conquistas,
    required this.onDataReload,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  void _handleMenuSelection(BuildContext context, String value) {
    if (value == 'sair') {
      AuthService().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    } else if (value == 'config') {
      // Navega para a tela de configurações/perfil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) => onDataReload());
    }
  }

  Future<void> _showNotificationDetails(
      BuildContext context, Notificacao notificacao) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.fundoCard,
          title: const Text('Notificação',
              style: TextStyle(color: AppColors.branco)),
          content: Text(notificacao.mensagem,
              style: const TextStyle(color: AppColors.branco)),
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

  @override
  Widget build(BuildContext context) {
    int naoLidas = notificacoes.where((n) => !n.lida).length;

    return AppBar(
      backgroundColor: AppColors.roxoHeader,
      elevation: 0,
      toolbarHeight: 60,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.branco),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      automaticallyImplyLeading: false,
      titleSpacing: showBackButton ? 0 : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNotificationButton(context, naoLidas),
          const SizedBox(width: 16),
          _buildChallengesAchievementsButton(context),
        ],
      ),
      actions: [
        if (usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserMenuButton(context, usuario!),
          ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, int naoLidas) {
    return PopupMenuButton<Notificacao>(
      onSelected: (notificacao) async {
        await ApiService().marcarNotificacaoComoLida(notificacao.id);
        _showNotificationDetails(context, notificacao);
        onDataReload();
      },
      color: AppColors.fundoCard,
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
        if (notificacoes.isEmpty) {
          return [
            const PopupMenuItem(
                enabled: false,
                child: Text("Nenhuma notificação",
                    style: TextStyle(color: AppColors.cinzaSub)))
          ];
        }
        return notificacoes.map((n) {
          return PopupMenuItem<Notificacao>(
              value: n,
              child: ListTile(
                  leading: Icon(
                      n.lida
                          ? Icons.check_circle_outline
                          : Icons.circle_notifications,
                      color:
                          n.lida ? AppColors.cinzaSub : AppColors.amareloClaro),
                  title: Text(n.mensagem,
                      style: TextStyle(
                          color: n.lida
                              ? AppColors.cinzaSub
                              : AppColors.branco))));
        }).toList();
      },
    );
  }

  Widget _buildChallengesAchievementsButton(BuildContext context) {
    final diarios = desafios
        .where((d) => d.tipo.trim().toLowerCase() == 'diario')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return PopupMenuButton<int>(
        color: AppColors.fundoCard,
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
                            const Text("Desafios diários",
                                style: TextStyle(
                                    color: AppColors.branco,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 8),
                            if (diarios.isEmpty)
                              const Text("Nenhum desafio diário",
                                  style: TextStyle(color: AppColors.cinzaSub))
                            else
                              Column(
                                  children: diarios.map((d) {
                                double progresso = d.progresso / max(1, d.meta);
                                return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: AppColors.cinzaSub,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(d.nome,
                                                style: const TextStyle(
                                                    color: AppColors.branco,
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
                                          style: const TextStyle(
                                              color: AppColors.branco)),
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
                            const Text("Conquistas",
                                style: TextStyle(
                                    color: AppColors.branco,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 8),
                            if (conquistas.isEmpty)
                              const Text("Nenhuma conquista",
                                  style: TextStyle(color: AppColors.cinzaSub))
                            else
                              Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: conquistas.take(20).map((c) {
                                    return SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Image.asset(
                                            "assets/conquistas/${c.imagem}",
                                            fit: BoxFit.contain));
                                  }).toList())
                          ])))
            ]);
  }

  Widget _buildUserMenuButton(BuildContext context, Usuario user) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      color: AppColors.fundoDropDown,
      offset: const Offset(0, 50),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(text: 'Sair', value: 'sair'),
      ],
      child: UserLevelAvatar(user: user, radius: 24),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      {required String text, required String value}) {
    return PopupMenuItem<String>(
        value: value,
        child: Container(
            decoration: BoxDecoration(
                color: AppColors.botaoDropDown,
                borderRadius: BorderRadius.circular(5)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Center(
                child: Text(text,
                    style: const TextStyle(
                        fontFamily: 'Jersey 10', color: AppColors.branco)))));
  }
}
