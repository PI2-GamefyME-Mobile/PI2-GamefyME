import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Dados para a CustomAppBar
  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  // Dados específicos da tela
  List<Atividade> _atividades = [];
  List<Atividade> _atividadesFiltradas = [];

  final TextEditingController _nomeController = TextEditingController();
  String? _recorrenciaSelecionada;
  String? _situacaoSelecionada;
  String? _dificuldadeSelecionada;

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
        _apiService.fetchAtividades(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchUsuarioConquistas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _atividadesFiltradas = _atividades;
        _notificacoes = results[2] as List<Notificacao>;
        _desafios = results[3] as List<DesafioPendente>;
        _conquistas = results[4] as List<Conquista>;
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

  void _filtrarAtividades() {
    List<Atividade> atividadesFiltradas = List.from(_atividades);

    if (_nomeController.text.isNotEmpty) {
      atividadesFiltradas = atividadesFiltradas
          .where((atividade) => atividade.nome
              .toLowerCase()
              .contains(_nomeController.text.toLowerCase()))
          .toList();
    }
    if (_recorrenciaSelecionada != null) {
      atividadesFiltradas = atividadesFiltradas
          .where((atividade) =>
              atividade.recorrencia == _recorrenciaSelecionada)
          .toList();
    }
    if (_situacaoSelecionada != null) {
      atividadesFiltradas = atividadesFiltradas
          .where((atividade) => atividade.situacao == _situacaoSelecionada)
          .toList();
    }
    if (_dificuldadeSelecionada != null) {
      atividadesFiltradas = atividadesFiltradas
          .where(
              (atividade) => atividade.dificuldade == _dificuldadeSelecionada)
          .toList();
    }
    setState(() => _atividadesFiltradas = atividadesFiltradas);
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
            _buildFiltros(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _atividadesFiltradas.isEmpty
                      ? const Center(
                          child: Text('Nenhuma atividade encontrada.',
                              style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: _atividadesFiltradas.length,
                          itemBuilder: (context, index) {
                            final atividade = _atividadesFiltradas[index];
                            return Card(
                              color: AppColors.fundoCard,
                              child: ListTile(
                                title: Text(atividade.nome,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                    'Dificuldade: ${atividade.dificuldade}\nSituação: ${atividade.situacao}',
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    // ... (O código dos filtros permanece o mesmo)
    return Column(
      children: [
        TextField(
          controller: _nomeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nome da Atividade',
            labelStyle: TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onChanged: (value) => _filtrarAtividades(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _recorrenciaSelecionada,
                hint: const Text('Recorrência',
                    style: TextStyle(color: Colors.white)),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColors.fundoCard,
                items: ['unica', 'recorrente'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _recorrenciaSelecionada = newValue;
                  });
                  _filtrarAtividades();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _situacaoSelecionada,
                hint: const Text('Situação',
                    style: TextStyle(color: Colors.white)),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppColors.fundoCard,
                items: ['ativa', 'realizada', 'cancelada']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _situacaoSelecionada = newValue;
                  });
                  _filtrarAtividades();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _dificuldadeSelecionada,
          hint:
              const Text('Dificuldade', style: TextStyle(color: Colors.white)),
          style: const TextStyle(color: Colors.white),
          dropdownColor: AppColors.fundoCard,
          items: [
            'muito_facil',
            'facil',
            'medio',
            'dificil',
            'muito_dificil'
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _dificuldadeSelecionada = newValue;
            });
            _filtrarAtividades();
          },
        ),
      ],
    );
  }
}