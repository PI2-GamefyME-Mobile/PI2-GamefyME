import 'package:flutter/material.dart';
import 'package:gamefymobile/cadastro_atividade_screen.dart';
import 'package:gamefymobile/conquistas_screen.dart';
import 'package:gamefymobile/desafios_screen.dart';
import 'package:gamefymobile/historico_screen.dart';
import 'package:gamefymobile/settings_screen.dart';
import 'package:intl/intl.dart';

import 'config/app_colors.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'realizar_atividade_screen.dart';
import 'editar_atividade_screen.dart';
import 'widgets/user_level_avatar.dart';
import 'widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Inicia na tela Home
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const <Widget>[
          DesafiosScreen(),
          ConquistasScreen(),
          HomeTab(), // O conteúdo da tela Home agora é um widget separado
          HistoricoScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        backgroundColor: AppColors.roxoHeader,
        selectedItemColor: AppColors.verdeLima,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield),
            label: 'Desafios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Conquistas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Atividades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// Widget para o conteúdo da aba Home
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

enum ScreenState { loading, loaded, error }

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  ScreenState _screenState = ScreenState.loading;
  Usuario? _usuario;
  List<Atividade> _atividades = [];
  List<Conquista> _conquistas = [];
  List<DesafioPendente> _desafios = [];
  List<Notificacao> _notificacoes = [];
  List<dynamic> _streakData = [];
  String _searchText = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _screenState = ScreenState.loading);
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchAtividades(),
        _apiService.fetchUsuarioConquistas(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchStreakStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _conquistas = results[2] as List<Conquista>;
        _desafios = results[3] as List<DesafioPendente>;
        _notificacoes = results[4] as List<Notificacao>;
        _streakData = results[5] as List<dynamic>;
        _screenState = ScreenState.loaded;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da home: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }

  Future<void> _showAvatarModal() async {
    final newAvatar = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.fundoCard,
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
      if (success) {
        _carregarDados();
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          color: AppColors.verdeLima,
          backgroundColor: AppColors.fundoCard,
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verdeLima,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CadastroAtividadeScreen()),
          );
          if (result == true) {
            _carregarDados();
          }
        },
        child: const Icon(Icons.add, color: AppColors.fundoEscuro, size: 30),
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.verdeLima));
      case ScreenState.error:
        return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Erro ao carregar dados.',
              style: TextStyle(color: AppColors.branco)),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roxoClaro),
              child: const Text('Tentar Novamente')),
        ]));
      case ScreenState.loaded:
        if (_usuario == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.verdeLima));
        }
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 150,
                  height: 220,
                  child: _buildUserInfoCard(_usuario!)),
              const SizedBox(width: 16),
              Expanded(
                  child: SizedBox(
                      height: 220, child: _buildStreakCard(_usuario!))),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: _buildAtividadesSection(),
            ),
          ],
        );
    }
  }

  Widget _buildUserInfoCard(Usuario user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: _showAvatarModal,
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
      ),
    );
  }

  Widget _buildStreakCard(Usuario usuario) {
    final double progress = usuario.expTotalNivel > 0
        ? usuario.exp.toDouble() / usuario.expTotalNivel.toDouble()
        : 0;
    
    // Formato para exibir o dia da semana
    final DateFormat dayFormatter = DateFormat('EEE', 'pt_BR');

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
              children: _streakData.map((dia) {
                final date = DateTime.parse(dia['date']);
                final String diaSemana = dayFormatter.format(date).toUpperCase();
                String imagePath;

                switch (dia['status']) {
                  case 'ativo':
                    imagePath = 'assets/images/fogo-ativo.png';
                    break;
                  case 'congelado':
                    imagePath = 'assets/images/fogo-congelado.png';
                    break;
                  default: // inativo
                    imagePath = 'assets/images/fogo-inativo.png';
                }
                
                return Expanded(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(diaSemana,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.branco)),
                    const SizedBox(height: 8),
                    Image.asset(imagePath,
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

  Widget _buildAtividadesSection() {
    final atividadesRecorrentes = _atividades
        .where((a) =>
            a.recorrencia != 'unica' &&
            a.situacao == 'ativa' &&
            a.nome.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
    final atividadesUnicas = _atividades
        .where((a) =>
            a.recorrencia == 'unica' &&
            a.situacao == 'ativa' &&
            a.nome.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchText = value),
            style: const TextStyle(
                color: AppColors.branco, fontFamily: 'Jersey 10'),
            decoration: InputDecoration(
              hintText: "Nome da atividade",
              hintStyle: const TextStyle(color: AppColors.cinzaSub),
              prefixIcon: const Icon(Icons.search, color: AppColors.cinzaSub),
              filled: true,
              fillColor: const Color(0xFFD9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Recorrentes'), Tab(text: 'Únicas')],
            labelColor: AppColors.verdeLima,
            unselectedLabelColor: AppColors.cinzaSub,
            indicatorColor: AppColors.verdeLima,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAtividadesList(atividadesRecorrentes),
                _buildAtividadesList(atividadesUnicas),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadesList(List<Atividade> atividades) {
    if (atividades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("Nenhuma atividade encontrada.",
              style: TextStyle(color: AppColors.cinzaSub)),
        ),
      );
    }

    return ListView.builder(
      itemCount: atividades.length,
      itemBuilder: (context, index) {
        final atividade = atividades[index];

        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: AppColors.roxoMedio,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: atividade.situacaoColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            // botão de editar à esquerda
            leading: IconButton(
              icon: const Icon(Icons.edit, color: AppColors.cinzaSub),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarAtividadeScreen(
                      atividade: atividade,
                      usuario: _usuario,
                      notificacoes: _notificacoes,
                      desafios: _desafios,
                      conquistas: _conquistas,
                    ),
                  ),
                );
                if (result == true && mounted) _carregarDados();
              },
            ),

            // todo o tile abre a atividade
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RealizarAtividadeScreen(atividadeId: atividade.id),
                ),
              );
              if (result == true && mounted) _carregarDados();
            },

            // nome + badges de informações
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        atividade.nome,
                        style: const TextStyle(
                          color: AppColors.branco,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.verdeLima,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${atividade.xp}xp',
                        style: const TextStyle(
                          color: AppColors.fundoEscuro,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Badges de informações
                Row(
                  children: [
                    // Badge de dificuldade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: atividade.dificuldadeColor.withOpacity(0.2),
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
                        color: atividade.recorrenciaColor.withOpacity(0.2),
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
                        color: atividade.situacaoColor.withOpacity(0.2),
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

            // ícone à direita para indicar clique
            trailing: const Icon(Icons.arrow_forward_ios,
                color: AppColors.cinzaSub, size: 18),
          ),
        );
      },
    );
  }
}
