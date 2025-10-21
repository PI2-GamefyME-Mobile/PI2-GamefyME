import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';

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
        _apiService.fetchTodasConquistas(),
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
            .where((c) =>
                c.nome.toLowerCase().contains(query.toLowerCase()))
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
          title: Text(conquista.nome, style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.asset(
                  'assets/conquistas/${conquista.imagem}',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, color: Colors.white, size: 100),
                ),
                const SizedBox(height: 16),
                Text(conquista.descricao, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  "+${conquista.xp} XP",
                  style: const TextStyle(
                      color: AppColors.amareloClaro, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      backgroundColor: AppColors.fundoEscuro,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFiltro(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conquistasFiltradas.isEmpty
                      ? const Center(
                          child: Text('Nenhuma conquista encontrada.',
                              style: TextStyle(color: Colors.white)))
                      : _buildListaConquistas(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltro() {
    return Column(
      children: [
        TextField(
          controller: _filtroController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Pesquisar por nome',
            labelStyle: const TextStyle(color: Colors.grey),
            suffixIcon: _filtroController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _filtroController.clear();
                      _filtrarConquistas('');
                    },
                  )
                : null,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.verdeLima),
            ),
          ),
        ),
        if (_filtroController.text.isNotEmpty)
          const SizedBox(height: 10),
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
                style: TextStyle(color: AppColors.fundoEscuro, fontWeight: FontWeight.bold),
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
    return ListView.builder(
      itemCount: _conquistasFiltradas.length,
      itemBuilder: (context, index) {
        final conquista = _conquistasFiltradas[index];
        return GestureDetector(
          onTap: () => _showConquistaDetails(context, conquista),
          child: Opacity(
            opacity: conquista.completada ? 1.0 : 0.4,
            child: Card(
              color: conquista.completada ? AppColors.fundoCard : AppColors.fundoCard.withOpacity(0.6),
              child: ListTile(
                leading: Stack(
                  children: [
                    Image.asset(
                      'assets/conquistas/${conquista.imagem}',
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.white),
                    ),
                    if (!conquista.completada)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  conquista.nome,
                  style: TextStyle(
                    color: conquista.completada ? Colors.white : Colors.grey,
                    fontSize: 16,
                    fontWeight: conquista.completada ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  conquista.descricao,
                  style: TextStyle(
                    color: conquista.completada ? Colors.grey : Colors.grey.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "+${conquista.xp} XP",
                      style: TextStyle(
                        color: conquista.completada ? AppColors.amareloClaro : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: conquista.completada ? 14 : 12,
                      ),
                    ),
                    if (!conquista.completada)
                      const Text(
                        "BLOQUEADA",
                        style: TextStyle(
                          color: Colors.red,
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