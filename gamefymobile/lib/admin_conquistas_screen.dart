import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'config/app_colors.dart';

class AdminConquistasScreen extends StatefulWidget {
  const AdminConquistasScreen({super.key});

  @override
  State<AdminConquistasScreen> createState() => _AdminConquistasScreenState();
}

class _AdminConquistasScreenState extends State<AdminConquistasScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];
  List<Map<String, dynamic>> _conquistasAdmin = [];

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
        _apiService.fetchConquistasAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _notificacoes = results[1] as List<Notificacao>;
        _desafios = results[2] as List<DesafioPendente>;
        _conquistas = results[3] as List<Conquista>;
        _conquistasAdmin = List<Map<String, dynamic>>.from(results[4] as List);
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

  Future<void> _excluirConquista(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fundoCard,
        title: const Text('Confirmar exclusão',
            style: TextStyle(color: AppColors.branco)),
        content: const Text(
          'Deseja realmente excluir esta conquista? Esta ação não pode ser desfeita.',
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
      await _apiService.excluirConquista(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conquista excluída com sucesso!'),
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

  void _abrirFormulario({Map<String, dynamic>? conquista}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioConquistaScreen(conquista: conquista),
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
        desafios: _desafios,
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
                        'Gerenciar Conquistas',
                        style: TextStyle(
                          color: AppColors.branco,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _abrirFormulario(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nova'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.verdeLima,
                          foregroundColor: AppColors.fundoEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _conquistasAdmin.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma conquista cadastrada',
                            style: TextStyle(color: AppColors.cinzaSub),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _conquistasAdmin.length,
                          itemBuilder: (context, index) {
                            final conquista = _conquistasAdmin[index];
                            final imagemUrl = conquista['imagem_url'];

                            return Card(
                              color: AppColors.fundoCard,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: imagemUrl != null &&
                                        imagemUrl.isNotEmpty
                                    ? Image.network(
                                        imagemUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(Icons.emoji_events,
                                                color: AppColors.amareloClaro,
                                                size: 50),
                                      )
                                    : const Icon(Icons.emoji_events,
                                        color: AppColors.amareloClaro,
                                        size: 50),
                                title: Text(
                                  conquista['nmconquista'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    color: AppColors.branco,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conquista['dsconquista'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.cinzaSub),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'XP: ${conquista['expconquista']}',
                                      style: const TextStyle(
                                        color: AppColors.amareloClaro,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (conquista['regra'] != null) ...[
                                      Text(
                                        'Regra: ${conquista['regra']}  |  Meta: ${conquista['parametro'] ?? ''}',
                                        style: const TextStyle(
                                          color: AppColors.cinzaSub,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.verdeLima),
                                      onPressed: () => _abrirFormulario(
                                          conquista: conquista),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _excluirConquista(
                                          conquista['idconquista']),
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

class FormularioConquistaScreen extends StatefulWidget {
  final Map<String, dynamic>? conquista;

  const FormularioConquistaScreen({super.key, this.conquista});

  @override
  State<FormularioConquistaScreen> createState() =>
      _FormularioConquistaScreenState();
}

class _FormularioConquistaScreenState extends State<FormularioConquistaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _xpController = TextEditingController();
  final _imagemController = TextEditingController();
  final _parametroController = TextEditingController();
  final _pomodoroMinutosController = TextEditingController(text: '60');

  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  String? _imagemSelecionada;
  String? _imagemUrl; // URL da imagem do servidor
  File? _imagemArquivo;

  // Campos dinâmicos de regra de conquista
  String? _regra; // chave da regra
  // campo 'período' removido do backend e da UI
  String? _dificuldadeAlvo; // para regra dificuldade
  String? _tipoDesafioAlvo; // para desafios por tipo

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosAppBar();
    if (widget.conquista != null) {
      _nomeController.text = widget.conquista!['nmconquista'] ?? '';
      _descricaoController.text = widget.conquista!['dsconquista'] ?? '';
      _xpController.text = widget.conquista!['expconquista']?.toString() ?? '';
      _imagemController.text = widget.conquista!['nmimagem'] ?? '';
      _imagemSelecionada = widget.conquista!['nmimagem'];
      _imagemUrl = widget.conquista!['imagem_url'];
      _regra = widget.conquista!['regra'];
        // período foi removido e não é mais carregado
      _parametroController.text =
          (widget.conquista!['parametro']?.toString() ?? '1');
      _dificuldadeAlvo = widget.conquista!['dificuldade_alvo'];
      _tipoDesafioAlvo = widget.conquista!['tipo_desafio_alvo'];
      _pomodoroMinutosController.text =
          (widget.conquista!['pomodoro_minutos']?.toString() ?? '60');
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
        _desafios = results[2] as List<DesafioPendente>;
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
    _imagemController.dispose();
    _parametroController.dispose();
    _pomodoroMinutosController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? imagem = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imagem == null) return;

      setState(() => _isLoading = true);

      try {
        final resultado = await _apiService.uploadImagemConquista(imagem.path);

        if (!mounted) return;
        setState(() {
          _imagemSelecionada = resultado['filename'];
          _imagemUrl = resultado['url'];
          _imagemController.text = resultado['filename'];
          _imagemArquivo = File(imagem.path);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dados = {
        'nmconquista': _nomeController.text,
        'dsconquista': _descricaoController.text,
        'expconquista': int.parse(_xpController.text),
        'nmimagem': _imagemController.text,
        if (_regra != null && _regra!.isNotEmpty) 'regra': _regra,
  // campo 'periodo' removido no backend; não enviar
        if (_parametroController.text.isNotEmpty)
          'parametro': int.tryParse(_parametroController.text) ?? 1,
        if (_dificuldadeAlvo != null && _dificuldadeAlvo!.isNotEmpty)
          'dificuldade_alvo': _dificuldadeAlvo,
        if (_tipoDesafioAlvo != null && _tipoDesafioAlvo!.isNotEmpty)
          'tipo_desafio_alvo': _tipoDesafioAlvo,
        if (_regra == 'pomodoro_concluidas_total' &&
            _pomodoroMinutosController.text.isNotEmpty)
          'pomodoro_minutos':
              int.tryParse(_pomodoroMinutosController.text) ?? 60,
      };

      if (widget.conquista != null) {
        await _apiService.atualizarConquista(
            widget.conquista!['idconquista'], dados);
      } else {
        await _apiService.criarConquista(dados);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.conquista != null
              ? 'Conquista atualizada com sucesso!'
              : 'Conquista criada com sucesso!'),
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
        desafios: _desafios,
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
              // Seção de regras
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fundoCard,
                  border: Border.all(color: AppColors.cinzaSub),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regra de Validação',
                      style: TextStyle(
                        color: AppColors.verdeLima,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _regra,
                      dropdownColor: AppColors.fundoCard,
                      style: const TextStyle(color: AppColors.branco),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Regra',
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
                          value: 'atividades_concluidas_total',
                          child: Text('Atividades concluídas (total)'),
                        ),
                        DropdownMenuItem(
                          value: 'recorrentes_concluidas_total',
                          child:
                              Text('Atividades recorrentes concluídas (total)'),
                        ),
                        DropdownMenuItem(
                          value: 'dificuldade_concluidas_total',
                          child: Text('Atividades por dificuldade (total)'),
                        ),
                        DropdownMenuItem(
                          value: 'desafios_concluidos_total',
                          child: Text('Desafios concluídos (total)'),
                        ),
                        DropdownMenuItem(
                          value: 'desafios_concluidos_por_tipo',
                          child: Text('Desafios concluídos por tipo'),
                        ),
                        DropdownMenuItem(
                          value: 'streak_conclusao',
                          child: Text('Streak de conclusão'),
                        ),
                        DropdownMenuItem(
                          value: 'streak_criacao',
                          child: Text('Streak de criação'),
                        ),
                        DropdownMenuItem(
                          value: 'pomodoro_concluidas_total',
                          child: Text('Atividades longas (>= min) concluídas'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _regra = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _parametroController,
                            style: const TextStyle(color: AppColors.branco),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Parâmetro/meta',
                              labelStyle: TextStyle(color: AppColors.cinzaSub),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.cinzaSub),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.verdeLima),
                              ),
                            ),
                          ),
                        ),
                        // Período removido
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_regra == 'dificuldade_concluidas_total')
                      DropdownButtonFormField<String>(
                        value: _dificuldadeAlvo,
                        dropdownColor: AppColors.fundoCard,
                        style: const TextStyle(color: AppColors.branco),
                        decoration: const InputDecoration(
                          labelText: 'Dificuldade alvo',
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
                              value: 'muito_facil', child: Text('Muito Fácil')),
                          DropdownMenuItem(
                              value: 'facil', child: Text('Fácil')),
                          DropdownMenuItem(
                              value: 'medio', child: Text('Médio')),
                          DropdownMenuItem(
                              value: 'dificil', child: Text('Difícil')),
                          DropdownMenuItem(
                              value: 'muito_dificil',
                              child: Text('Muito Difícil')),
                        ],
                        onChanged: (v) => setState(() => _dificuldadeAlvo = v),
                      ),
                    if (_regra == 'desafios_concluidos_por_tipo')
                      DropdownButtonFormField<String>(
                        value: _tipoDesafioAlvo,
                        dropdownColor: AppColors.fundoCard,
                        style: const TextStyle(color: AppColors.branco),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de desafio alvo',
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
                              value: 'diario', child: Text('Diário')),
                          DropdownMenuItem(
                              value: 'semanal', child: Text('Semanal')),
                          DropdownMenuItem(
                              value: 'mensal', child: Text('Mensal')),
                          DropdownMenuItem(
                              value: 'unico', child: Text('Único')),
                        ],
                        onChanged: (v) => setState(() => _tipoDesafioAlvo = v),
                      ),
                    if (_regra == 'pomodoro_concluidas_total')
                      TextFormField(
                        controller: _pomodoroMinutosController,
                        style: const TextStyle(color: AppColors.branco),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutos mínimos (Pomodoro)',
                          labelStyle: TextStyle(color: AppColors.cinzaSub),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.cinzaSub),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.verdeLima),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(color: AppColors.branco),
                decoration: const InputDecoration(
                  labelText: 'Nome da Conquista',
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
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
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
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cinzaSub),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Imagem da Conquista',
                      style: TextStyle(
                        color: AppColors.cinzaSub,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_imagemArquivo != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imagemArquivo!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else if (_imagemUrl != null && _imagemUrl!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imagemUrl!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.emoji_events,
                              color: AppColors.amareloClaro,
                              size: 150,
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.image,
                          color: AppColors.cinzaSub,
                          size: 150,
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _selecionarImagem,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Selecionar Imagem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cinzaSub,
                        foregroundColor: AppColors.branco,
                      ),
                    ),
                    if (_imagemSelecionada != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Arquivo: $_imagemSelecionada',
                        style: const TextStyle(
                          color: AppColors.verdeLima,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // Campo oculto para validação
              TextFormField(
                controller: _imagemController,
                style: const TextStyle(color: AppColors.branco),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Selecione uma imagem';
                  return null;
                },
                enabled: false,
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
                        widget.conquista != null ? 'ATUALIZAR' : 'CRIAR',
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
