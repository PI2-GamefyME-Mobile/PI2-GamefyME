import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'package:gamefymobile/config/app_colors.dart';
import 'package:gamefymobile/config/theme_provider.dart';
import 'package:gamefymobile/widgets/user_level_avatar.dart';
import 'package:gamefymobile/estatisticas_screen.dart';
import 'package:gamefymobile/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:gamefymobile/main.dart';

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
  List<Usuario> _leaderboard =
      []; // Adicionado para guardar os dados da leaderboard
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

  Future<void> _showAvatarModal() async {
    if (!mounted) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final newAvatar = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: themeProvider.fundoCard,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: List.generate(4, (index) {
              final avatarName = 'avatar${index + 1}.png';
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(avatarName),
                child: Image.asset('assets/avatares/$avatarName'),
              );
            }),
          ),
        );
      },
    );

    if (newAvatar != null && newAvatar != _usuario?.imagemPerfil) {
      final success = await _apiService.updateProfilePicture(newAvatar);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada!'),
            backgroundColor: Colors.green,
          ),
        );
        await _carregarDados();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar a foto de perfil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        _apiService.fetchConquistas(),
        _apiService.fetchLeaderboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _notificacoes = results[1] as List<Notificacao>;
        _desafios = results[2] as List<DesafioPendente>;
        _conquistas = results[3] as List<Conquista>;
        _leaderboard =
            results[4] as List<Usuario>; // Armazena os dados da leaderboard
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

      if (!mounted) return;
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

  Future<void> _confirmarInativacao() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.fundoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Inativar Conta',
          style: TextStyle(color: themeProvider.textoTexto, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja inativar sua conta?\n\n'
          'Sua conta será desativada e você não poderá fazer login até reativá-la. '
          'Você poderá reativar sua conta a qualquer momento através do seu e-mail cadastrado.',
          style: TextStyle(color: themeProvider.textoCinza),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: themeProvider.textoTexto,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.inativarConta();
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Conta inativada com sucesso. Você será desconectado.'),
            backgroundColor: Colors.orange,
          ),
        );
        // Realiza logout e redireciona imediatamente para a tela inicial (WelcomePage)
        await AuthService().logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDangerZone(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "Zona de Perigo",
                style: TextStyle(
                  color: themeProvider.textoTexto,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Inativar sua conta irá desconectá-lo do sistema. "
            "Você poderá reativar sua conta a qualquer momento através do seu e-mail cadastrado.",
            style: TextStyle(color: themeProvider.textoCinza, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmarInativacao,
              icon: const Icon(Icons.block, color: Colors.red),
              label: const Text(
                'Inativar Minha Conta',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.fundoApp,
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.verdeLima))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: TextStyle(color: themeProvider.textoTexto)))
              : _buildBody(themeProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleEdit,
        backgroundColor: AppColors.verdeLima,
        child: Icon(_isEditing ? Icons.close : Icons.edit),
      ),
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_usuario == null) {
      return Center(
        child: Text("Nenhum usuário encontrado",
            style: TextStyle(color: themeProvider.textoTexto)),
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
              child: SizedBox(height: 220, child: _buildStreakCard(_usuario!)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _isEditing ? _buildEditForm() : _buildUserInfoDetails(),
        if (_isEditing) ...[
          const SizedBox(height: 20),
          _buildDangerZone(themeProvider),
        ],
        const SizedBox(height: 20),
        _buildLeaderboard(
            themeProvider), // Widget da leaderboard adicionado aqui
        const SizedBox(height: 20),
        _buildEstatisticasButton(themeProvider), // Botão para estatísticas
      ],
    );
  }

  Widget _buildUserInfoDetails() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Informações do Usuário",
              style: TextStyle(
                  color: themeProvider.textoTexto,
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: themeProvider.textoCinza, fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: themeProvider.textoTexto, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Editar Informações",
                style: TextStyle(
                    color: themeProvider.textoTexto,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nomeController,
              label: 'Nome',
              validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: themeProvider.textoTexto),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeProvider.textoCinza),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeProvider.textoCinza),
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showAvatarModal,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserLevelAvatar(user: user, radius: 46),
                Container(
                  margin: const EdgeInsets.only(right: 6, bottom: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.roxoProfundo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeProvider.textoTexto,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Toque para alterar a foto',
            style: TextStyle(
              color: themeProvider.textoCinza,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Usuario usuario) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final double progress = usuario.expTotalNivel > 0
        ? usuario.exp.toDouble() / usuario.expTotalNivel.toDouble()
        : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Dias contínuos de atividades",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textoTexto)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: usuario.streakData.map((dia) {
                return Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(dia.diaSemana,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textoTexto)),
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
                  style: TextStyle(
                      color: themeProvider.textoTexto,
                      fontWeight: FontWeight.bold)),
              Text('Nível ${usuario.nivel}',
                  style: TextStyle(
                      color: themeProvider.textoTexto,
                      fontWeight: FontWeight.bold)),
              Text('${usuario.expTotalNivel} XP',
                  style: TextStyle(
                      color: themeProvider.textoTexto,
                      fontWeight: FontWeight.bold)),
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

  Widget _buildLeaderboard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.leaderboard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leaderboard",
            style: TextStyle(
                color: themeProvider.textoTexto,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final user = _leaderboard[index];
              return Card(
                color: themeProvider.leaderboardPerfil,
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
                          style: TextStyle(color: themeProvider.textoAtividade),
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
                          style: TextStyle(color: themeProvider.textoCinza)),
                    ],
                  ),
                  onTap: () => _abrirModalUsuario(context, user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalUsuario(BuildContext context, Usuario usuario) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final api = _apiService;
    List<dynamic> trofeus = [];
    String? erro;
    try {
      trofeus = await api.fetchTrofeusUsuario(usuario.id);
    } catch (e) {
      erro = 'Erro ao buscar conquistas: $e';
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: themeProvider.fundoCard,
          title: Row(
            children: [
              UserLevelAvatar(user: usuario, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nome,
                      style: TextStyle(
                        color: themeProvider.textoTexto,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Nível ${usuario.nivel} · ${usuario.exp} XP',
                      style: TextStyle(color: themeProvider.textoCinza, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: erro != null
                ? Text(erro, style: TextStyle(color: themeProvider.textoCinza))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Troféus desbloqueados',
                          style: TextStyle(
                              color: themeProvider.textoTexto,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      trofeus.isEmpty
                          ? Text('Nenhum troféu ainda',
                              style: TextStyle(color: themeProvider.textoCinza))
                          : SizedBox(
                              height: 100,
                              child: GridView.builder(
                                shrinkWrap: true,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemCount: trofeus.length,
                                itemBuilder: (ctx, i) {
                                  final t = trofeus[i] as Map<String, dynamic>;
                                  final url = (t['imagem_url'] ?? '') as String;
                                  return Tooltip(
                                    message: (t['nmconquista'] ?? '') as String,
                                    child: url.isNotEmpty
                                        ? Image.network(url, fit: BoxFit.cover)
                                        : const Icon(Icons.emoji_events, color: AppColors.amareloClaro, size: 28),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstatisticasButton(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progressão Visual",
                style: TextStyle(
                  color: themeProvider.textoTexto,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.analytics, color: AppColors.roxoHeader, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EstatisticasScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart, color: Colors.white),
              label: const Text(
                'Ver Minhas Estatísticas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roxoHeader,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veja gráficos detalhados, heat map e seu progresso',
            style: TextStyle(
              color: themeProvider.textoCinza,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
