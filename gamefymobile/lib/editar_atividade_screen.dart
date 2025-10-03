import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_colors.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'widgets/custom_app_bar.dart';

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
    'muito_facil': 0, 'facil': 1, 'medio': 2, 'dificil': 3, 'muito_dificil': 4,
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
        0: 'muito_facil', 1: 'facil', 2: 'medio', 3: 'dificil', 4: 'muito_dificil'
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

  Future<void> _removerAtividade() async {
  final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.fundoCard, // COR PERSONALIZADA
          title: const Text(
            'Confirmar Remoção',
            style: TextStyle(color: AppColors.branco),
          ),
          content: const Text(
            'Tem certeza de que deseja remover esta atividade?',
            style: TextStyle(color: AppColors.branco),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.cinzaSub)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover',
                  style: TextStyle(color: Colors.red)),
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
          content: Text('Erro ao remover a atividade.'),
          backgroundColor: Colors.red));
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
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
              _buildTextField(
                  controller: _nomeController,
                  label: 'Nome da atividade',
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: _descricaoController,
                  label: 'Descrição',
                  maxLines: 3),
              const SizedBox(height: 20),
              _buildSectionTitle('Recorrência'),
              _buildRecorrenciaSelector(),
              const SizedBox(height: 20),
              _buildTextField(
                  controller: _tempoEstimadoController,
                  label: 'Tempo estimado',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixText: 'minutos',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    final t = int.tryParse(v);
                    if (t == null || t <= 0 || t > 240) {
                      return 'Valor inválido';
                    }
                    return null;
                  }),
              const SizedBox(height: 20),
              _buildSectionTitle('Dificuldade'),
              _buildDificuldadeSelector(), // Alteração aqui
              const SizedBox(height: 40),
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _removerAtividade,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.fundoEscuro)
                            : const Text('REMOVER',
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

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.branco,
            fontSize: 16,
            fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      int maxLines = 1,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      String? suffixText,
      String? Function(String?)? validator}) {
    return TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style:
            const TextStyle(color: AppColors.branco, fontFamily: 'Jersey 10'),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontFamily: 'Jersey 10'),
            suffixText: suffixText,
            alignLabelWithHint: true));
  }

  Widget _buildRecorrenciaSelector() {
    return Row(children: [
      Expanded(child: _buildRecorrenciaButton('ÚNICA', 'unica')),
      const SizedBox(width: 10),
      Expanded(child: _buildRecorrenciaButton('RECORRENTE', 'recorrente'))
    ]);
  }

  Widget _buildRecorrenciaButton(String text, String value) {
    final bool isSelected = _recorrenciaSelecionada == value;
    return ElevatedButton(
        onPressed: () => setState(() => _recorrenciaSelecionada = value),
        style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? AppColors.roxoClaro : AppColors.fundoCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(text,
            style: TextStyle(
                color: isSelected ? AppColors.branco : AppColors.cinzaSub)));
  }

  // NOVA VERSÃO DO WIDGET DE DIFICULDADE
  Widget _buildDificuldadeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        bool isSelected = index == _dificuldadeSelecionada;
        return GestureDetector(
          onTap: () => setState(() => _dificuldadeSelecionada = index),
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Image.asset(
              'assets/images/dificuldade${index + 1}.png',
              width: 40,
              height: 40,
            ),
          ),
        );
      }),
    );
  }
}