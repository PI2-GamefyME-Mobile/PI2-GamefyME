import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';

class AdminDesafiosScreen extends StatefulWidget {
  const AdminDesafiosScreen({super.key});

  @override
  State<AdminDesafiosScreen> createState() => _AdminDesafiosScreenState();
}

class _AdminDesafiosScreenState extends State<AdminDesafiosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafiosPendentes = [];
  List<Conquista> _conquistas = [];
  List<Map<String, dynamic>> _desafios = [];

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
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchConquistas(),
        _apiService.fetchDesafiosAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _notificacoes = results[1] as List<Notificacao>;
        _desafiosPendentes = results[2] as List<DesafioPendente>;
        _conquistas = results[3] as List<Conquista>;
        _desafios = List<Map<String, dynamic>>.from(results[4] as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _excluirDesafio(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fundoCard,
        title: const Text('Confirmar exclusão',
            style: TextStyle(color: AppColors.branco)),
        content: const Text(
          'Deseja realmente excluir este desafio? Esta ação não pode ser desfeita.',
          style: TextStyle(color: AppColors.cinzaSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.cinzaSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _apiService.excluirDesafio(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desafio excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _abrirFormulario({Map<String, dynamic>? desafio}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioDesafioScreen(desafio: desafio),
      ),
    ).then((resultado) {
      if (resultado == true) {
        _carregarDados();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafiosPendentes,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
        showBackButton: true,
      ),
      backgroundColor: AppColors.fundoEscuro,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gerenciar Desafios',
                        style: TextStyle(
                          color: AppColors.branco,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _abrirFormulario(),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeLima,
                          foregroundColor: AppColors.fundoEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _desafios.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum desafio cadastrado',
                            style: TextStyle(color: AppColors.cinzaSub),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _desafios.length,
                          itemBuilder: (context, index) {
                            final desafio = _desafios[index];
                            return Card(
                              color: AppColors.fundoCard,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.emoji_events,
                                  color: AppColors.amareloClaro,
                                  size: 32,
                                ),
                                title: Text(
                                  desafio['nmdesafio'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    color: AppColors.branco,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      desafio['dsdesafio'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.cinzaSub),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tipo: ${desafio['tipo']} | XP: ${desafio['expdesafio']}',
                                      style: const TextStyle(
                                        color: AppColors.amareloClaro,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (desafio['parametro'] != null)
                                      Text(
                                        'Meta: ${desafio['parametro']}',
                                        style: const TextStyle(
                                          color: AppColors.cinzaSub,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (desafio['tipo'] == 'unico')
                                      Builder(builder: (context) {
                                        final dtInicioStr = desafio['dtinicio'] as String?;
                                        final dtFimStr = desafio['dtfim'] as String?;
                                        String periodo = '';
                                        try {
                                          if (dtInicioStr != null && dtInicioStr.isNotEmpty) {
                                            final di = DateTime.parse(dtInicioStr);
                                            periodo +=
                                                'Início: ${di.day.toString().padLeft(2, '0')}/${di.month.toString().padLeft(2, '0')}/${di.year}';
                                          }
                                          if (dtFimStr != null && dtFimStr.isNotEmpty) {
                                            final df = DateTime.parse(dtFimStr);
                                            if (periodo.isNotEmpty) periodo += '  ·  ';
                                            periodo +=
                                                'Fim: ${df.day.toString().padLeft(2, '0')}/${df.month.toString().padLeft(2, '0')}/${df.year}';
                                          }
                                        } catch (_) {}
                                        if (periodo.isEmpty) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            periodo,
                                            style: const TextStyle(
                                              color: AppColors.cinzaSub,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.verdeLima),
                                      onPressed: () =>
                                          _abrirFormulario(desafio: desafio),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _excluirDesafio(desafio['iddesafio']),
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
    );
  }
}

class FormularioDesafioScreen extends StatefulWidget {
  final Map<String, dynamic>? desafio;

  const FormularioDesafioScreen({super.key, this.desafio});

  @override
  State<FormularioDesafioScreen> createState() =>
      _FormularioDesafioScreenState();
}

class _FormularioDesafioScreenState extends State<FormularioDesafioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _xpController = TextEditingController();
  final _parametroController = TextEditingController();

  String _tipoSelecionado = 'diario';
  String _tipoLogicaSelecionada = 'atividades_concluidas';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafiosPendentes = [];
  List<Conquista> _conquistas = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosAppBar();
    if (widget.desafio != null) {
      _nomeController.text = widget.desafio!['nmdesafio'] ?? '';
      _descricaoController.text = widget.desafio!['dsdesafio'] ?? '';
      _xpController.text = widget.desafio!['expdesafio']?.toString() ?? '';
      _parametroController.text =
          widget.desafio!['parametro']?.toString() ?? '';
      _tipoSelecionado = widget.desafio!['tipo'] ?? 'diario';
      _tipoLogicaSelecionada =
          widget.desafio!['tipo_logica'] ?? 'atividades_concluidas';

      if (widget.desafio!['dtinicio'] != null) {
        _dataInicio = DateTime.parse(widget.desafio!['dtinicio']);
      }
      if (widget.desafio!['dtfim'] != null) {
        _dataFim = DateTime.parse(widget.desafio!['dtfim']);
      }
    }
  }

  Future<void> _carregarDadosAppBar() async {
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchConquistas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _notificacoes = results[1] as List<Notificacao>;
        _desafiosPendentes = results[2] as List<DesafioPendente>;
        _conquistas = results[3] as List<Conquista>;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados para a AppBar: $e");
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _xpController.dispose();
    _parametroController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dados = {
        'nmdesafio': _nomeController.text,
        'dsdesafio': _descricaoController.text,
        'tipo': _tipoSelecionado,
        'expdesafio': int.parse(_xpController.text),
        'tipo_logica': _tipoLogicaSelecionada,
        'parametro': int.parse(_parametroController.text),
        if (_dataInicio != null) 'dtinicio': _dataInicio!.toIso8601String(),
        if (_dataFim != null) 'dtfim': _dataFim!.toIso8601String(),
      };

      if (widget.desafio != null) {
        await _apiService.atualizarDesafio(widget.desafio!['iddesafio'], dados);
      } else {
        await _apiService.criarDesafio(dados);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.desafio != null
              ? 'Desafio atualizado com sucesso!'
              : 'Desafio criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafiosPendentes,
        conquistas: _conquistas,
        onDataReload: _carregarDadosAppBar,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: AppColors.branco),
                decoration: const InputDecoration(
                  labelText: 'Nome do Desafio',
                  labelStyle: TextStyle(color: AppColors.cinzaSub),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaSub),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.verdeLima),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                style: const TextStyle(color: AppColors.branco),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: AppColors.cinzaSub),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaSub),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.verdeLima),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                style: const TextStyle(color: AppColors.branco),
                dropdownColor: AppColors.fundoCard,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  labelStyle: TextStyle(color: AppColors.cinzaSub),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaSub),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.verdeLima),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'diario', child: Text('Diário')),
                  DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                  DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                  DropdownMenuItem(value: 'unico', child: Text('Único')),
                ],
                onChanged: (v) => setState(() => _tipoSelecionado = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoLogicaSelecionada,
                style: const TextStyle(color: AppColors.branco),
                dropdownColor: AppColors.fundoCard,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Lógica',
                  labelStyle: TextStyle(color: AppColors.cinzaSub),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cinzaSub),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.verdeLima),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'atividades_concluidas',
                      child: Text('Atividades Concluídas')),
                  DropdownMenuItem(
                      value: 'recorrentes_concluidas',
                      child: Text('Recorrentes Concluídas')),
                  DropdownMenuItem(
                      value: 'min_dificeis', child: Text('Mínimo Difíceis')),
                  DropdownMenuItem(
                      value: 'desafios_concluidos',
                      child: Text('Desafios Concluídos')),
                  DropdownMenuItem(
                      value: 'atividades_criadas',
                      child: Text('Atividades Criadas')),
                ],
                onChanged: (v) => setState(() => _tipoLogicaSelecionada = v!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xpController,
                      style: const TextStyle(color: AppColors.branco),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP',
                        labelStyle: TextStyle(color: AppColors.cinzaSub),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.cinzaSub),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.verdeLima),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _parametroController,
                      style: const TextStyle(color: AppColors.branco),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Meta (Parâmetro)',
                        labelStyle: TextStyle(color: AppColors.cinzaSub),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.cinzaSub),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.verdeLima),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Período de Validade (Opcional para diário/semanal/mensal, obrigatório para único)',
                style: TextStyle(
                    color: AppColors.verdeLima,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: AppColors.fundoCard,
                title: Text(
                  _dataInicio == null
                      ? 'Selecionar Data de Início (opcional)'
                      : 'Início: ${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}',
                  style: const TextStyle(color: AppColors.branco),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dataInicio != null && _tipoSelecionado != 'unico')
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.cinzaSub),
                        onPressed: () => setState(() => _dataInicio = null),
                      ),
                    const Icon(Icons.calendar_today, color: AppColors.verdeLima),
                  ],
                ),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataInicio ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (data != null) {
                    setState(() => _dataInicio = data);
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: AppColors.fundoCard,
                title: Text(
                  _dataFim == null
                      ? 'Selecionar Data de Fim (opcional)'
                      : 'Fim: ${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}',
                  style: const TextStyle(color: AppColors.branco),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_dataFim != null && _tipoSelecionado != 'unico')
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.cinzaSub),
                        onPressed: () => setState(() => _dataFim = null),
                      ),
                    const Icon(Icons.calendar_today, color: AppColors.verdeLima),
                  ],
                ),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataFim ??
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (data != null) {
                    setState(() => _dataFim = data);
                  }
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeLima,
                  foregroundColor: AppColors.fundoEscuro,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: AppColors.fundoEscuro)
                    : Text(
                        widget.desafio != null ? 'ATUALIZAR' : 'CRIAR',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
