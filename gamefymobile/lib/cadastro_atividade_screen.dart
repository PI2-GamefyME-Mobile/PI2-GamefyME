import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_colors.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'widgets/custom_app_bar.dart';

class CadastroAtividadeScreen extends StatefulWidget {
  const CadastroAtividadeScreen({super.key});

  @override
  State<CadastroAtividadeScreen> createState() =>
      _CadastroAtividadeScreenState();
}

class _CadastroAtividadeScreenState extends State<CadastroAtividadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoEstimadoController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _recorrenciaSelecionada = 'unica';
  int _dificuldadeSelecionada = 2; // 0-4 (Muito Fácil a Muito Difícil)
  bool _isLoading = false;

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosAppBar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _tempoEstimadoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosAppBar() async {
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchUsuarioConquistas(),
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final Map<int, String> dificuldades = {
        0: 'muito_facil', 1: 'facil', 2: 'medio', 3: 'dificil', 4: 'muito_dificil'
      };
      final result = await _apiService.cadastrarAtividade(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        recorrencia: _recorrenciaSelecionada,
        tpEstimado: int.parse(_tempoEstimadoController.text),
        dificuldade: dificuldades[_dificuldadeSelecionada]!,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message']), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erro: ${result['message']}"),
            backgroundColor: Colors.red));
      }
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nomeController,
                label: 'Nome da atividade',
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descricaoController,
                label: 'Descrição',
                maxLines: 3,
              ),
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
              _buildSectionTitle('Dificuldade'),
              _buildDificuldadeSelector(), // Alteração aqui
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verdeLima,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: AppColors.fundoEscuro)
                    : const Text('CADASTRAR',
                        style: TextStyle(
                            fontFamily: 'Jersey 10',
                            color: AppColors.fundoEscuro,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
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