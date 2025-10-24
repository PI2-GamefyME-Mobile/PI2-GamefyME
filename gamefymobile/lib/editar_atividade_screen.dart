import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_colors.dart';
import 'config/theme_provider.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'widgets/custom_app_bar.dart';
import 'utils/common_utils.dart';

class EditarAtividadeScreen extends StatefulWidget {
  final Atividade atividade;
  final Usuario? usuario;
  final List<Notificacao> notificacoes;
  final List<DesafioPendente> desafios;
  final List<Conquista> conquistas;

  const EditarAtividadeScreen({
    super.key,
    required this.atividade,
    required this.usuario,
    required this.notificacoes,
    required this.desafios,
    required this.conquistas,
  });

  @override
  State<EditarAtividadeScreen> createState() => _EditarAtividadeScreenState();
}

class _EditarAtividadeScreenState extends State<EditarAtividadeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _tempoEstimadoController;
  final ApiService _apiService = ApiService();

  late String _recorrenciaSelecionada;
  late int _dificuldadeSelecionada;
  bool _isLoading = false;

  final Map<String, int> _dificuldadeMap = {
    'muito_facil': 0,
    'facil': 1,
    'medio': 2,
    'dificil': 3,
    'muito_dificil': 4,
  };

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.atividade.nome);
    _descricaoController =
        TextEditingController(text: widget.atividade.descricao);
    _tempoEstimadoController =
        TextEditingController(text: widget.atividade.tpEstimado.toString());
    _recorrenciaSelecionada = widget.atividade.recorrencia;
    _dificuldadeSelecionada =
        _dificuldadeMap[widget.atividade.dificuldade] ?? 2;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _tempoEstimadoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final Map<int, String> dificuldades = {
        0: 'muito_facil',
        1: 'facil',
        2: 'medio',
        3: 'dificil',
        4: 'muito_dificil'
      };
      final result = await _apiService.updateAtividade(
        id: widget.atividade.id,
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        recorrencia: _recorrenciaSelecionada,
        tpEstimado: int.parse(_tempoEstimadoController.text),
        dificuldade: dificuldades[_dificuldadeSelecionada]!,
        dtAtividade: widget.atividade.dtAtividade,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success']) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erro: ${result['message']}"),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _cancelarAtividade() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: themeProvider.fundoCard,
            title: Text(
              'Confirmar Remoção',
              style: TextStyle(color: themeProvider.textoTexto),
            ),
            content: Text(
              'Tem certeza de que deseja cancelar esta atividade?',
              style: TextStyle(color: themeProvider.textoTexto),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar',
                    style: TextStyle(color: themeProvider.textoCinza)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Cancelar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      final success = await _apiService.cancelAtividade(widget.atividade.id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao cancelar a atividade.'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.fundoApp,
      appBar: CustomAppBar(
        usuario: widget.usuario,
        notificacoes: widget.notificacoes,
        desafios: widget.desafios,
        conquistas: widget.conquistas,
        onDataReload: () {},
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommonUtils.buildTextField(
                context: context,
                controller: _nomeController,
                label: 'Nome da atividade',
                hint: 'Digite o nome da atividade',
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              CommonUtils.buildTextField(
                context: context,
                controller: _descricaoController,
                label: 'Descrição',
                hint: 'Digite a descrição da atividade',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              CommonUtils.buildSectionTitle(context, 'Recorrência'),
              CommonUtils.buildRecorrenciaSelector(
                context: context,
                recorrenciaSelecionada: _recorrenciaSelecionada,
                onChanged: (value) =>
                    setState(() => _recorrenciaSelecionada = value),
              ),
              const SizedBox(height: 20),
              CommonUtils.buildTextField(
                context: context,
                controller: _tempoEstimadoController,
                label: 'Tempo estimado',
                hint: 'Digite o tempo em minutos',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  final int? tempo = int.tryParse(value);
                  if (tempo == null || tempo <= 0 || tempo > 240) {
                    return 'Máximo de 240 minutos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CommonUtils.buildSectionTitle(context, 'Dificuldade'),
              CommonUtils.buildDificuldadeSelector(
                context: context,
                dificuldadeSelecionada: _dificuldadeSelecionada,
                onChanged: (value) =>
                    setState(() => _dificuldadeSelecionada = value),
              ),
              const SizedBox(height: 40),
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _cancelarAtividade,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.fundoEscuro)
                            : const Text('CANCELAR',
                                style: TextStyle(
                                    fontFamily: 'Jersey 10',
                                    color: AppColors.branco,
                                    fontSize: 18)))),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verdeLima,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.fundoEscuro)
                            : const Text('SALVAR',
                                style: TextStyle(
                                    fontFamily: 'Jersey 10',
                                    color: AppColors.fundoEscuro,
                                    fontSize: 18))))
              ])
            ],
          ),
        ),
      ),
    );
  }
}
