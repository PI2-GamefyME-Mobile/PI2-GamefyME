import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';
import 'utils/responsive_utils.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];
  List<Conquista> _conquistasFiltradas = [];
  final TextEditingController _filtroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _filtroController.addListener(() {
      _filtrarConquistas(_filtroController.text);
    });
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchConquistas(todasConquistas: true),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _conquistas = results[1] as List<Conquista>;
        _conquistasFiltradas = _conquistas;
        _notificacoes = results[2] as List<Notificacao>;
        _desafios = results[3] as List<DesafioPendente>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados.')),
      );
    }
  }

  void _filtrarConquistas(String query) {
    setState(() {
      if (query.isEmpty) {
        _conquistasFiltradas = _conquistas;
      } else {
        _conquistasFiltradas = _conquistas
            .where((c) => c.nome.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showConquistaDetails(BuildContext context, Conquista conquista) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.fundoCard,
          title:
              Text(conquista.nome, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                conquista.imagemUrl != null && conquista.imagemUrl!.isNotEmpty
                    ? Image.network(
                        conquista.imagemUrl!,
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.emoji_events, color: Colors.white, size: 100),
                      )
                    : Image.asset(
                        'assets/conquistas/${conquista.imagem}',
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.emoji_events, color: Colors.white, size: 100),
                      ),
                const SizedBox(height: 16),
                Text(conquista.descricao,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  "+${conquista.xp} XP",
                  style: const TextStyle(
                      color: AppColors.amareloClaro,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Fechar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _usuario?.isAdmin ?? false;

    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      backgroundColor: themeProvider.fundoApp,
      body: Padding(
        padding: ResponsiveUtils.adaptivePadding(context),
        child: Column(
          children: [
            if (isAdmin)
              Padding(
                padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.isSmallScreen(context) ? 6 : 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin-conquistas')
                          .then((_) => _carregarDados());
                    },
                    icon: Icon(Icons.admin_panel_settings,
                        size: ResponsiveUtils.adaptiveIconSize(context,
                            small: 20, medium: 22, large: 24)),
                    label: const Text('Gerenciar Conquistas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roxoProfundo,
                      foregroundColor: AppColors.verdeLima,
                      padding: EdgeInsets.symmetric(
                          vertical:
                              ResponsiveUtils.isSmallScreen(context) ? 12 : 14),
                    ),
                  ),
                ),
              ),
            _buildFiltro(),
            ResponsiveUtils.adaptiveVerticalSpace(context,
                small: 12, medium: 16, large: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conquistasFiltradas.isEmpty
                      ? Center(
                          child: Text('Nenhuma conquista encontrada.',
                              style:
                                  TextStyle(color: themeProvider.textoTexto)))
                      : _buildListaConquistas(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltro() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        TextField(
          controller: _filtroController,
          style: TextStyle(color: themeProvider.textoTexto),
          decoration: InputDecoration(
            labelText: 'Pesquisar por nome',
            labelStyle: TextStyle(color: themeProvider.textoCinza),
            suffixIcon: _filtroController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: themeProvider.textoTexto),
                    onPressed: () {
                      _filtroController.clear();
                      _filtrarConquistas('');
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeProvider.textoCinza),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.verdeLima),
            ),
          ),
        ),
        if (_filtroController.text.isNotEmpty) const SizedBox(height: 10),
        if (_filtroController.text.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _filtroController.clear();
                _filtrarConquistas('');
              },
              icon: const Icon(Icons.clear_all, color: AppColors.fundoEscuro),
              label: const Text(
                'Limpar Filtro',
                style: TextStyle(
                    color: AppColors.fundoEscuro, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeLima,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListaConquistas() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListView.builder(
      itemCount: _conquistasFiltradas.length,
      itemBuilder: (context, index) {
        final conquista = _conquistasFiltradas[index];
        return GestureDetector(
          onTap: () => _showConquistaDetails(context, conquista),
          child: Opacity(
            opacity: conquista.completada ? 1.0 : 0.4,
            child: Card(
              color: conquista.completada
                  ? themeProvider.cardAtividade
                  : themeProvider.cardAtividade.withValues(alpha: 0.6),
              child: ListTile(
                leading: Stack(
                  children: [
                    conquista.imagemUrl != null && conquista.imagemUrl!.isNotEmpty
                        ? Image.network(
                            conquista.imagemUrl!,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.emoji_events,
                                color: themeProvider.textoAtividade),
                          )
                        : Image.asset(
                            'assets/conquistas/${conquista.imagem}',
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.emoji_events,
                                color: themeProvider.textoAtividade),
                          ),
                    if (!conquista.completada)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.lock,
                            color: themeProvider.textoAtividade,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  conquista.nome,
                  style: TextStyle(
                    color: conquista.completada
                        ? themeProvider.textoAtividade
                        : themeProvider.textoCinza,
                    fontSize: 16,
                    fontWeight: conquista.completada
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  conquista.descricao,
                  style: TextStyle(
                    color: themeProvider.textoAtividade,
                    fontSize: 12,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "+${conquista.xp} XP",
                      style: TextStyle(
                        color: conquista.completada
                            ? AppColors.amareloClaro
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: conquista.completada ? 14 : 12,
                      ),
                    ),
                    if (!conquista.completada)
                      Text(
                        "BLOQUEADA",
                        style: TextStyle(
                          color: themeProvider.textoCinza,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
