import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'package:gamefymobile/config/app_colors.dart';
import 'package:gamefymobile/widgets/user_level_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();

  Usuario? _usuario;
  List<Usuario> _leaderboard = []; // Adicionado para guardar os dados da leaderboard
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  bool _isEditing = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Adicionado fetchLeaderboard() ao Future.wait
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchUsuarioConquistas(),
        _apiService.fetchLeaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _notificacoes = results[1] as List<Notificacao>;
        _desafios = results[2] as List<DesafioPendente>;
        _conquistas = results[3] as List<Conquista>;
        _leaderboard = results[4] as List<Usuario>; // Armazena os dados da leaderboard
        _nomeController.text = _usuario!.nome;
        _emailController.text = _usuario!.email;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Erro ao carregar dados.";
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _apiService.updateUser(
        nome: _nomeController.text,
        email: _emailController.text,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dados atualizados com sucesso!'),
              backgroundColor: Colors.green),
        );
        _toggleEdit();
        _carregarDados();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro: ${result['message']}"),
              backgroundColor: Colors.red),
        );
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
        onDataReload: _carregarDados,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.verdeLima))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.white)))
              : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleEdit,
        backgroundColor: AppColors.verdeLima,
        child: Icon(_isEditing ? Icons.close : Icons.edit),
      ),
    );
  }

  Widget _buildBody() {
    if (_usuario == null) {
      return const Center(
        child:
            Text("Nenhum usuário encontrado", style: TextStyle(color: Colors.white)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 150, height: 220, child: _buildUserInfoCard(_usuario!)),
            const SizedBox(width: 16),
            Expanded(
              child:
                  SizedBox(height: 220, child: _buildStreakCard(_usuario!)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _isEditing ? _buildEditForm() : _buildUserInfoDetails(),
        const SizedBox(height: 20),
        _buildLeaderboard(), // Widget da leaderboard adicionado aqui
      ],
    );
  }

  // Widget para construir a Leaderboard
  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Leaderboard",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true, // Importante para aninhar ListView
            physics: const NeverScrollableScrollPhysics(), // Desabilita scroll aninhado
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final user = _leaderboard[index];
              return Card(
                color: AppColors.fundoCard, // Ou uma cor de sua preferência
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.verdeLima,
                    ),
                  ),
                  title: Row(
                    children: [
                      UserLevelAvatar(user: user, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user.nome,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Nível ${user.nivel}',
                          style:
                              const TextStyle(color: AppColors.amareloClaro)),
                      Text('${user.exp} XP',
                          style: const TextStyle(color: AppColors.cinzaSub)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildUserInfoDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Informações do Usuário",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildDetailRow("Nome:", _usuario!.nome),
          _buildDetailRow("Email:", _usuario!.email),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.cinzaSub, fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Editar Informações",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nomeController,
              label: 'Nome',
              validator: (value) =>
                  value!.isEmpty ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _salvarAlteracoes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoClaro,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SALVAR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.branco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.cinzaSub),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.cinzaSub),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.verdeLima),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Usuario user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserLevelAvatar(user: user, radius: 46),
          const SizedBox(height: 12),
          Text(
            user.nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.branco,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Usuario usuario) {
    final double progress = usuario.expTotalNivel > 0
        ? usuario.exp.toDouble() / usuario.expTotalNivel.toDouble()
        : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Dias contínuos de atividades",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: usuario.streakData.map((dia) {
                return Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(dia.diaSemana,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.branco)),
                    const SizedBox(height: 8),
                    Image.asset('assets/images/${dia.imagem}',
                        width: 28, height: 28),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${usuario.exp} XP',
                  style: const TextStyle(
                      color: AppColors.branco, fontWeight: FontWeight.bold)),
              Text('Nível ${usuario.nivel}',
                  style: const TextStyle(
                      color: AppColors.branco, fontWeight: FontWeight.bold)),
              Text('${usuario.expTotalNivel} XP',
                  style: const TextStyle(
                      color: AppColors.branco, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.roxoProfundo,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ]),
        ],
      ),
    );
  }
}