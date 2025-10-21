import 'dart:async';
import 'package:flutter/material.dart';
import 'config/app_colors.dart';
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

class _RealizarAtividadeScreenState extends State<RealizarAtividadeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final TimerService _timerService = TimerService();
  
  ScreenState _screenState = ScreenState.loading;
  
  Atividade? _atividade;
  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  Timer? _timer;
  Duration _duration = Duration.zero;
  Duration _maxDuration = Duration.zero;
  bool get _isTimerRunning => _timer?.isActive ?? false;
  bool _isFinished = false;

  StreamSubscription? _timerSubscription;
  StreamSubscription? _completionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregarDados();
    _setupTimerListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timerSubscription?.cancel();
    _completionSubscription?.cancel();
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
        _duration = _maxDuration;
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
      activityName: _atividade!.nome,
      minutes: _duration.inMinutes,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_duration.inSeconds > 0) {
        setState(() => _duration = _duration - const Duration(seconds: 1));
      } else {
        _stopTimer(finished: true);
        _concluirAtividadeAutomaticamente();
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
      _duration = _maxDuration;
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
              const Text('Erro ao carregar a atividade.',
                  style: TextStyle(
                      color: Colors.white, 
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
        return SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(children: [
                  _buildActivityStreakSection(context),
                  const SizedBox(height: 24),
                  _buildTimerSection(context),
                  const SizedBox(height: 24),
                  _buildTaskSection(context),
                  const SizedBox(height: 24),
                  _buildButtonsSection(context),
                  const SizedBox(height: 20),
                ])));
    }
  }

  Widget _buildActivityStreakSection(BuildContext context) {
    final double expProgress = _usuario!.expTotalNivel > 0
        ? _usuario!.exp.toDouble() / _usuario!.expTotalNivel.toDouble()
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.fundoCard, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]),
      child: Column(children: [
        const Text('Sequência de Dias',
            style: TextStyle(
                fontFamily: 'Jersey 10', 
                fontSize: 22, 
                color: AppColors.verdeLima,
                letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: AppColors.roxoProfundo.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _usuario!.streakData
                    .map((day) => Text(day.diaSemana,
                        style: const TextStyle(
                            fontFamily: 'Jersey 10',
                            color: AppColors.cinzaSub,
                            fontSize: 14)))
                    .toList()),
            const SizedBox(height: 8),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _usuario!.streakData
                    .map((day) => Image.asset("assets/images/${day.imagem}",
                        width: 32, height: 32))
                    .toList()),
          ]),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_usuario!.exp} XP',
                  style: const TextStyle(
                      color: AppColors.verdeLima, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.roxoProfundo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Nível ${_usuario!.nivel}',
                    style: const TextStyle(
                        color: AppColors.branco, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Text('${_usuario!.expTotalNivel} XP',
                  style: const TextStyle(
                      color: AppColors.cinzaSub, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: expProgress.clamp(0.0, 1.0),
                backgroundColor: AppColors.roxoProfundo.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
                minHeight: 12,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTimerSection(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final progress = _maxDuration.inSeconds > 0
        ? _duration.inSeconds / _maxDuration.inSeconds
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppColors.fundoCard, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]),
      child: Column(children: [
        SizedBox(
            width: 200,
            height: 200,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.roxoProfundo.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _isFinished ? AppColors.verdeLima : AppColors.roxoClaro)),
              Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$minutes:$seconds',
                          style: const TextStyle(
                              fontFamily: 'Jersey 10',
                              fontSize: 64,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      if (_isFinished)
                        const Text('Tempo esgotado!',
                            style: TextStyle(
                                fontFamily: 'Jersey 10',
                                fontSize: 16,
                                color: AppColors.verdeLima)),
                    ],
                  )),
            ])),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.roxoProfundo.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
                icon: const Icon(Icons.replay, color: AppColors.verdeLima, size: 32),
                onPressed: _resetTimer,
                tooltip: 'Reiniciar'),
          ),
          const SizedBox(width: 40),
          Container(
            decoration: BoxDecoration(
              color: _isTimerRunning 
                  ? AppColors.roxoClaro.withOpacity(0.2)
                  : AppColors.verdeLima.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
                icon: Icon(
                    _isTimerRunning ? Icons.pause : Icons.play_arrow,
                    color: _isTimerRunning ? AppColors.roxoClaro : AppColors.verdeLima,
                    size: 40),
                onPressed: _toggleTimer,
                tooltip: _isTimerRunning ? 'Pausar' : 'Iniciar'),
          ),
        ]),
      ]),
    );
  }

  Widget _buildTaskSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.fundoCard, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]),
      child: Column(
        children: [
          Text(_atividade?.nome ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Jersey 10', 
                  fontSize: 28, 
                  color: Colors.white,
                  height: 1.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                icon: Icons.stars_rounded,
                label: '${_atividade?.xp ?? 0} XP',
                color: AppColors.amareloClaro,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.repeat_rounded,
                label: _atividade?.recorrencia.toUpperCase() ?? 'ÚNICA',
                color: AppColors.roxoClaro,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.roxoProfundo.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/dificuldade$dificuldadeLevel.png',
                      height: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      FilterHelpers.getDificuldadeDisplayName(_atividade?.dificuldade ?? 'facil'),
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Jersey 10',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fundoCard,
                foregroundColor: AppColors.cinzaSub,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.cinzaSub.withOpacity(0.3), width: 1),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Jersey 10',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _concluirAtividade,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeLima,
                foregroundColor: AppColors.fundoEscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.verdeLima.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'CONCLUIR',
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
        ],
      ),
    ]);
  }
}