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
  String? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchUsuarioConquistas(),
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

  void _filtrarConquistas(String? tipo) {
    setState(() {
      _filtroTipo = tipo;
      if (_filtroTipo == null) {
        _conquistasFiltradas = _conquistas;
      } else {
        _conquistasFiltradas = _conquistas
            .where((c) => c.nome.toLowerCase().contains(_filtroTipo!.toLowerCase()))
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
            _buildFiltroTipo(),
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

  Widget _buildFiltroTipo() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _filtroTipo,
            hint: const Text('Filtrar por tipo',
                style: TextStyle(color: Colors.white)),
            style: const TextStyle(color: Colors.white),
            dropdownColor: AppColors.fundoCard,
            items: ['ATIVIDADE', 'PRODUTIVIDADE', 'RECORRÊNCIA']
                .map((String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)))
                .toList(),
            onChanged: (newValue) => _filtrarConquistas(newValue),
          ),
        ),
        if (_filtroTipo != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () => _filtrarConquistas(null),
          )
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
            opacity: conquista.completada ? 1.0 : 0.5,
            child: Card(
              color: AppColors.fundoCard,
              child: ListTile(
                leading: Image.asset(
                  'assets/conquistas/${conquista.imagem}',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
                title: Text(
                  conquista.nome,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  conquista.descricao,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Text(
                  "+${conquista.xp} XP",
                  style: const TextStyle(
                      color: AppColors.amareloClaro, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}