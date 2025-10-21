import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  static const String _keyTimerEndTime = 'timer_end_time';
  static const String _keyTimerDuration = 'timer_duration';
  static const String _keyTimerRunning = 'timer_running';
  static const String _keyActivityId = 'timer_activity_id';
  static const String _keyActivityName = 'timer_activity_name';
  static const String _keyActivityXP = 'timer_activity_xp';

  Timer? _backgroundTimer;
  final _timerController = StreamController<Duration>.broadcast();
  final _completionController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;
  Stream<Map<String, dynamic>> get completionStream => _completionController.stream;

  Future<void> startTimer({
    required Duration duration,
    required int activityId,
    required String activityName,
    required int activityXP,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().add(duration);

    await prefs.setString(_keyTimerEndTime, endTime.toIso8601String());
    await prefs.setInt(_keyTimerDuration, duration.inSeconds);
    await prefs.setBool(_keyTimerRunning, true);
    await prefs.setInt(_keyActivityId, activityId);
    await prefs.setString(_keyActivityName, activityName);
    await prefs.setInt(_keyActivityXP, activityXP);

    _startBackgroundTimer();
    debugPrint('Timer iniciado: ${duration.inMinutes} minutos, termina em: $endTime');
  }

  Future<void> stopTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTimerRunning, false);
    _backgroundTimer?.cancel();
    debugPrint('Timer parado');
  }

  Future<void> resetTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTimerEndTime);
    await prefs.remove(_keyTimerDuration);
    await prefs.remove(_keyTimerRunning);
    await prefs.remove(_keyActivityId);
    await prefs.remove(_keyActivityName);
    await prefs.remove(_keyActivityXP);
    _backgroundTimer?.cancel();
    debugPrint('Timer resetado');
  }

  Future<Duration?> getRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_keyTimerRunning) ?? false;
    
    if (!isRunning) return null;

    final endTimeStr = prefs.getString(_keyTimerEndTime);
    if (endTimeStr == null) return null;

    final endTime = DateTime.parse(endTimeStr);
    final now = DateTime.now();
    
    if (now.isAfter(endTime)) {
      return Duration.zero;
    }

    return endTime.difference(now);
  }

  Future<bool> isTimerRunning() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTimerRunning) ?? false;
  }

  Future<Map<String, dynamic>?> getTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_keyTimerRunning) ?? false;
    
    if (!isRunning) return null;

    final activityId = prefs.getInt(_keyActivityId);
    final activityName = prefs.getString(_keyActivityName);
    final activityXP = prefs.getInt(_keyActivityXP);
    final duration = prefs.getInt(_keyTimerDuration);
    final remaining = await getRemainingTime();

    if (activityId == null || activityName == null || activityXP == null || duration == null) {
      return null;
    }

    return {
      'activityId': activityId,
      'activityName': activityName,
      'activityXP': activityXP,
      'duration': Duration(seconds: duration),
      'remaining': remaining ?? Duration.zero,
    };
  }

  void _startBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = await getRemainingTime();
      
      if (remaining == null) {
        timer.cancel();
        return;
      }

      _timerController.add(remaining);

      if (remaining.inSeconds <= 0) {
        timer.cancel();
        await _handleTimerCompletion();
      }
    });
  }

  Future<void> _handleTimerCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final activityId = prefs.getInt(_keyActivityId);
    final activityName = prefs.getString(_keyActivityName);
    final activityXP = prefs.getInt(_keyActivityXP);

    if (activityId != null && activityName != null && activityXP != null) {
      _completionController.add({
        'activityId': activityId,
        'activityName': activityName,
        'activityXP': activityXP,
      });
      debugPrint('Timer completado: $activityName');
    }

    await resetTimer();
  }

  Future<void> resumeTimerIfNeeded() async {
    final isRunning = await isTimerRunning();
    if (isRunning) {
      final remaining = await getRemainingTime();
      if (remaining != null && remaining.inSeconds > 0) {
        _startBackgroundTimer();
        debugPrint('Timer retomado: ${remaining.inMinutes} minutos restantes');
      } else if (remaining != null && remaining.inSeconds <= 0) {
        await _handleTimerCompletion();
      }
    }
  }

  void dispose() {
    _backgroundTimer?.cancel();
    _timerController.close();
    _completionController.close();
  }
}
