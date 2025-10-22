import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFiltros(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _atividadesFiltradas.isEmpty
                      ? Center(
                          child: Text('Nenhuma atividade encontrada.',
                              style: TextStyle(color: themeProvider.textoTexto)))
                      : ListView.builder(
                          itemCount: _atividadesFiltradas.length,
                          itemBuilder: (context, index) {
                            final atividade = _atividadesFiltradas[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: themeProvider.cardAtividade,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: atividade.situacaoColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                title: Text(
                                  atividade.nome,
                                  style: TextStyle(
                                    color: themeProvider.textoAtividade,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Badge de dificuldade
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: atividade.dificuldadeColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: atividade.dificuldadeColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Image.asset(
                                                atividade.dificuldadeImage,
                                                width: 14,
                                                height: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                FilterHelpers.getDificuldadeDisplayName(atividade.dificuldade).toUpperCase(),
                                                style: TextStyle(
                                                  color: atividade.dificuldadeColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Badge de recorrência
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: atividade.recorrenciaColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: atividade.recorrenciaColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                atividade.recorrenciaIcon,
                                                size: 12,
                                                color: atividade.recorrenciaColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                FilterHelpers.getRecorrenciaDisplayName(atividade.recorrencia).toUpperCase(),
                                                style: TextStyle(
                                                  color: atividade.recorrenciaColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Badge de situação
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: atividade.situacaoColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: atividade.situacaoColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            FilterHelpers.getSituacaoDisplayName(atividade.situacao).toUpperCase(),
                                            style: TextStyle(
                                              color: atividade.situacaoColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        // Campo de busca por nome
        TextField(
          controller: _nomeController,
          style: TextStyle(color: themeProvider.textoTexto),
          decoration: InputDecoration(
            labelText: 'Nome da Atividade',
            labelStyle: TextStyle(color: themeProvider.textoTexto),
            suffixIcon: _nomeController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: themeProvider.textoTexto),
                    onPressed: () {
                      _nomeController.clear();
                      _filtrarAtividades();
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
          onChanged: (value) => _filtrarAtividades(),
        ),
        const SizedBox(height: 10),
        
        // Filtros de recorrência e situação
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _recorrenciaSelecionada,
                hint: Text('Recorrência',
                    style: TextStyle(color: themeProvider.textoTexto)),
                style: TextStyle(color: themeProvider.textoTexto),
                dropdownColor: themeProvider.fundoCard,
                items: FilterHelpers.getRecorrenciaOptions().map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(option['label']!),
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
                hint: Text('Situação',
                    style: TextStyle(color: themeProvider.textoTexto)),
                style: TextStyle(color: themeProvider.textoTexto),
                dropdownColor: themeProvider.fundoCard,
                items: FilterHelpers.getSituacaoOptions().map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(option['label']!),
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
        
        // Filtro de dificuldade
        DropdownButtonFormField<String>(
          initialValue: _dificuldadeSelecionada,
          hint: Text('Dificuldade', style: TextStyle(color: themeProvider.textoTexto)),
          style: TextStyle(color: themeProvider.textoTexto),
          dropdownColor: themeProvider.fundoCard,
          items: FilterHelpers.getDificuldadeOptions().map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _dificuldadeSelecionada = newValue;
            });
            _filtrarAtividades();
          },
        ),
        const SizedBox(height: 10),
        
        // Botão para limpar todos os filtros
        if (_nomeController.text.isNotEmpty || 
            _recorrenciaSelecionada != null || 
            _situacaoSelecionada != null || 
            _dificuldadeSelecionada != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _limparFiltros,
              icon: const Icon(Icons.clear_all, color: AppColors.fundoEscuro),
              label: const Text(
                'Limpar Filtros',
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

  void _limparFiltros() {
    setState(() {
      _nomeController.clear();
      _recorrenciaSelecionada = null;
      _situacaoSelecionada = null;
      _dificuldadeSelecionada = null;
    });
    _filtrarAtividades();
  }
}