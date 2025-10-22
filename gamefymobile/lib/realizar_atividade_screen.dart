import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/timer_service.dart';
import 'widgets/custom_app_bar.dart';

enum ScreenState { loading, loaded, error }

class RealizarAtividadeScreen extends StatefulWidget {
  final int atividadeId;
  const RealizarAtividadeScreen({super.key, required this.atividadeId});

  @override
  State<RealizarAtividadeScreen> createState() =>
      _RealizarAtividadeScreenState();
}

class _RealizarAtividadeScreenState extends State<RealizarAtividadeScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final TimerService _timerService = TimerService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  ScreenState _screenState = ScreenState.loading;
  
  Atividade? _atividade;
  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  Timer? _timer;
  Duration _duration = Duration.zero;
  Duration _maxDuration = Duration.zero;
  Duration _totalRemaining = Duration.zero;
  Duration _totalOriginal = Duration.zero;
  bool get _isTimerRunning => _timer?.isActive ?? false;
  bool _isFinished = false;
  bool _isPomodoro = false;
  bool _inFocusPhase = true; // true=foco 25, false=pausa 5

  StreamSubscription? _timerSubscription;
  StreamSubscription? _completionSubscription;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Configurar animação de pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _carregarDados();
    _setupTimerListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timerSubscription?.cancel();
    _completionSubscription?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimerState();
    }
  }

  void _setupTimerListeners() {
    _timerSubscription = _timerService.timerStream.listen((remaining) {
      if (mounted) {
        setState(() {
          _duration = remaining;
          if (remaining.inSeconds <= 0 && !_isFinished) {
            _isFinished = true;
            _onTimerComplete();
          }
        });
      }
    });

    _completionSubscription = _timerService.completionStream.listen((data) async {
      await _notificationService.showActivityCompletedNotification(
        activityName: data['activityName'],
        xpGained: data['activityXP'],
      );
      await _notificationService.cancelTimerNotification();
      if (mounted) {
        await _concluirAtividadeAutomaticamente();
      }
    });
  }

  void _onTimerComplete() {
    // Iniciar animação de pulso
    _pulseController.repeat(reverse: true);
    
    // Tocar som de conclusão
    try {
      // Usando um tom de sistema como fallback se não houver arquivo de áudio
      _audioPlayer.play(AssetSource('sounds/timer_complete.mp3')).catchError((e) {
        debugPrint('Erro ao tocar som: $e');
      });
    } catch (e) {
      debugPrint('Erro ao configurar som: $e');
    }
  }

  Future<void> _checkTimerState() async {
    final timerData = await _timerService.getTimerData();
    if (timerData != null && timerData['activityId'] == widget.atividadeId) {
      if (mounted) {
        setState(() {
          _duration = timerData['remaining'] as Duration;
          _isFinished = _duration.inSeconds <= 0;
        });
      }
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _screenState = ScreenState.loading);
    try {
      final results = await Future.wait([
        _apiService.fetchAtividade(widget.atividadeId),
        _apiService.fetchUsuario(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchUsuarioConquistas(),
      ]);
      if (!mounted) return;
      setState(() {
        _atividade = results[0] as Atividade;
        _usuario = results[1] as Usuario;
        _notificacoes = results[2] as List<Notificacao>;
        _desafios = results[3] as List<DesafioPendente>;
        _conquistas = results[4] as List<Conquista>;
        _maxDuration = Duration(minutes: _atividade!.tpEstimado);
        _totalOriginal = _maxDuration;
        _totalRemaining = _maxDuration;
        _isPomodoro = _atividade!.tpEstimado > 60;
        if (_isPomodoro) {
          // Começa na fase de foco de 25 min (ou o restante, se menor)
          final focus = Duration(minutes: 25);
          _duration = _totalRemaining < focus ? _totalRemaining : focus;
          _inFocusPhase = true;
        } else {
          _duration = _maxDuration;
        }
        _screenState = ScreenState.loaded;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da atividade: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }

  void _startTimer() {
    if (_isTimerRunning || _isFinished) return;
    
    _timerService.startTimer(
      duration: _duration,
      activityId: _atividade!.id,
      activityName: _atividade!.nome,
      activityXP: _atividade!.xp,
    );

    _notificationService.showTimerStartedNotification(
      activityName: _isPomodoro
          ? '${_atividade!.nome} • ${_inFocusPhase ? 'Foco' : 'Pausa'}'
          : _atividade!.nome,
      minutes: _duration.inMinutes,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_duration.inSeconds > 0) {
        setState(() {
          _duration = _duration - const Duration(seconds: 1);
          if (_isPomodoro && _inFocusPhase) {
            // Apenas o tempo de foco conta para o restante total
            _totalRemaining -= const Duration(seconds: 1);
          }
        });
      } else {
        _stopTimer(finished: true);
        if (_isPomodoro) {
          _onPhaseComplete();
        } else {
          _concluirAtividadeAutomaticamente();
        }
      }
    });
  }

  void _stopTimer({bool finished = false}) {
    if (finished) {
      setState(() => _isFinished = true);
      _timerService.stopTimer();
    } else {
      _timerService.stopTimer();
    }
    _timer?.cancel();
    _notificationService.cancelTimerNotification();
    setState(() {});
  }

  void _resetTimer() {
    _stopTimer();
    _timerService.resetTimer();
    setState(() {
      _totalRemaining = _totalOriginal;
      if (_isPomodoro) {
        final focus = const Duration(minutes: 25);
        _duration = _totalRemaining < focus ? _totalRemaining : focus;
  _inFocusPhase = true;
      } else {
        _duration = _maxDuration;
      }
      _isFinished = false;
    });
  }

  void _toggleTimer() {
    _isTimerRunning ? _stopTimer() : _startTimer();
  }

  Future<void> _concluirAtividadeAutomaticamente() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    final success = await _apiService.realizarAtividade(_atividade!.id);
    
    await _notificationService.showActivityCompletedNotification(
      activityName: _atividade!.nome,
      xpGained: _atividade!.xp,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '🎉 "${_atividade!.nome}" concluída! (+${_atividade!.xp} XP)',
              style: const TextStyle(fontFamily: 'Jersey 10', fontSize: 16)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2)));
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        await _timerService.resetTimer();
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível completar a atividade automaticamente.',
              style: TextStyle(fontFamily: 'Jersey 10', fontSize: 16)),
          backgroundColor: Colors.red));
    }
  }

  void _onPhaseComplete() async {
    // Sinalização visual e sonora já feita em _onTimerComplete
    if (!_isPomodoro) return;

    // Se acabou a fase de foco, inicia pausa se ainda há tempo total para cumprir
    if (_inFocusPhase) {
      _inFocusPhase = false;
      final breakDur = const Duration(minutes: 5);
      // Se já cumpriu o tempo total de foco, conclui atividade
      if (_totalRemaining <= Duration.zero) {
        await _concluirAtividadeAutomaticamente();
        return;
      }
      setState(() {
        _duration = breakDur;
      });
      _startTimer();
    } else {
      // Fim da pausa, volta ao foco
  _inFocusPhase = true;
      final focus = const Duration(minutes: 25);
      if (_totalRemaining <= Duration.zero) {
        await _concluirAtividadeAutomaticamente();
        return;
      }
      final nextFocus = _totalRemaining < focus ? _totalRemaining : focus;
      setState(() {
        _duration = nextFocus;
      });
      _startTimer();
    }
  }

  Future<void> _concluirAtividade() async {
    final success = await _apiService.realizarAtividade(_atividade!.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '"${_atividade!.nome}" realizada (+${_atividade!.xp} XP)!',
              style: const TextStyle(fontFamily: 'Jersey 10', fontSize: 16)),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível realizar a atividade.',
              style: TextStyle(fontFamily: 'Jersey 10', fontSize: 16)),
          backgroundColor: Colors.red));
    }
  }

  int get dificuldadeLevel {
    switch (_atividade?.dificuldade) {
      case 'muito_facil': return 1;
      case 'facil': return 2;
      case 'medio': return 3;
      case 'dificil': return 4;
      case 'muito_dificil': return 5;
      default: return 1;
    }
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
        showBackButton: true,
      ),
      body: _buildBody(),
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
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
        Text('Erro ao carregar a atividade.',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).textoTexto, 
            fontFamily: 'Jersey 10',
            fontSize: 20)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                  onPressed: _carregarDados,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente',
                      style: TextStyle(fontFamily: 'Jersey 10', fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeLima,
          foregroundColor: AppColors.fundoEscuro,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  )),
            ]));
      case ScreenState.loaded:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Provider.of<ThemeProvider>(context).fundoApp,
                Provider.of<ThemeProvider>(context).fundoApp.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  // Seção do Timer
                  _buildTimerSection(context),
                  const SizedBox(height: 28),
                  // Seção de Informações da Tarefa
                  _buildTaskSection(context),
                  const SizedBox(height: 28),
                  // Seção de Botões
                  _buildButtonsSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
    }
  }
  
  Widget _buildTimerSection(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
  // Progresso geral baseado no restante total
  final totalRemaining = _isPomodoro ? _totalRemaining.inSeconds : _duration.inSeconds;
  final totalOriginal = _isPomodoro ? _totalOriginal.inSeconds : _maxDuration.inSeconds;
  final progress = totalOriginal > 0 ? (totalRemaining / totalOriginal) : 0.0;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.fundoCard,
            themeProvider.fundoCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isFinished ? AppColors.roxoClaro : AppColors.verdeLima)
                .withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isFinished ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isFinished ? AppColors.roxoClaro : AppColors.verdeLima)
                          .withValues(alpha: _isTimerRunning ? 0.3 : 0.1),
                      blurRadius: _isTimerRunning ? 30 : 15,
                      spreadRadius: _isTimerRunning ? 5 : 0,
                    ),
                  ],
                ),
                child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.roxoProfundo.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isFinished
                          ? AppColors.roxoClaro
                          : _isTimerRunning
                              ? AppColors.verdeLima
                              : AppColors.verdeLima.withValues(alpha: 0.5),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$minutes:$seconds',
                          style: TextStyle(
                            fontFamily: 'Jersey 10',
                            fontSize: 72,
                            color: themeProvider.textoTexto,
                            fontWeight: FontWeight.bold,
                            height: 1,
                            shadows: [
                              Shadow(
                                color: (_isFinished ? AppColors.roxoClaro : AppColors.verdeLima)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        // Controles do Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botão Reiniciar
            _buildTimerControlButton(
              icon: Icons.replay_rounded,
              label: 'Reiniciar',
              onPressed: _resetTimer,
              color: AppColors.roxoClaro,
              isSecondary: true,
            ),
            const SizedBox(width: 24),
            // Botão Play/Pause
            _buildTimerControlButton(
              icon: _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _isTimerRunning ? 'Pausar' : 'Iniciar',
              onPressed: _toggleTimer,
              color: _isTimerRunning ? AppColors.amareloClaro : AppColors.verdeLima,
              isSecondary: false,
              isPrimary: true,
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildTimerControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isSecondary = false,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: !isSecondary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: isSecondary ? color.withValues(alpha: 0.15) : null,
            boxShadow: [
              if (!isSecondary)
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
            ],
            border: isSecondary
                ? Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                  )
                : null,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isSecondary ? color : AppColors.fundoEscuro,
              size: isPrimary ? 42 : 32,
            ),
            onPressed: onPressed,
            tooltip: label,
            iconSize: isPrimary ? 42 : 32,
            padding: EdgeInsets.all(isPrimary ? 16 : 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Jersey 10',
            fontSize: 12,
            color: isSecondary ? color : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.fundoCard,
            themeProvider.fundoCard.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.roxoProfundo.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da Atividade
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  _atividade?.nome ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jersey 10',
                    fontSize: 32,
                    color: themeProvider.textoTexto,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: AppColors.roxoProfundo.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Badges de Informações
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoChip(
                  icon: Icons.stars_rounded,
                  label: '${_atividade?.xp ?? 0} XP',
                  color: AppColors.amareloClaro,
                  isPrimary: true,
                ),
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  label: '${_atividade?.tpEstimado ?? 0} min',
                  color: AppColors.verdeLima,
                ),
                _buildInfoChip(
                  icon: Icons.repeat_rounded,
                  label: _atividade?.recorrencia.toUpperCase() ?? 'ÚNICA',
                  color: _atividade?.recorrenciaColor ?? AppColors.recorrenciaUnica,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Badge de Dificuldade
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.roxoProfundo.withValues(alpha: 0.6),
                    AppColors.roxoProfundo.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.roxoProfundo.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.roxoProfundo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/dificuldade$dificuldadeLevel.png',
                    height: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Dificuldade: ',
                    style: TextStyle(
                      color: themeProvider.textoAtividade,
                      fontSize: 14,
                      fontFamily: 'Jersey 10',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    FilterHelpers.getDificuldadeDisplayName(_atividade?.dificuldade ?? 'facil'),
                    style: TextStyle(
                      color: themeProvider.textoAtividade,
                      fontSize: 14,
                      fontFamily: 'Jersey 10',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.15),
                ],
              )
            : null,
        color: !isPrimary ? color.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: isPrimary ? 2 : 1.5,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isPrimary ? 20 : 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isPrimary ? 16 : 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jersey 10',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        // Botão principal de Concluir
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.verdeLima,
                AppColors.verdeLima.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeLima.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _concluirAtividade,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.fundoEscuro,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  'CONCLUIR ATIVIDADE',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Jersey 10',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Botão secundário de Cancelar
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.textoCinza.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.fundoCard.withValues(alpha: 0.5),
              foregroundColor: themeProvider.textoCinza,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close_rounded, size: 24),
                SizedBox(width: 10),
                Text(
                  'CANCELAR',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Jersey 10',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Texto informativo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: themeProvider.textoCinza.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'A atividade será concluída quando o timer terminar',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.textoCinza.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}