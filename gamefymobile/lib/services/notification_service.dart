import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
      debugPrint('NotificationService inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificação tocada: ${response.payload}');
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    try {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Erro ao solicitar permissões: $e');
    }
  }

  Future<void> showActivityCompletedNotification({
    required String activityName,
    required int xpGained,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      debugPrint('Notificações não suportadas na web');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'activity_timer_channel',
      'Timer de Atividades',
      channelDescription: 'Notificações quando o timer de atividades termina',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Atividade Concluída',
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        0,
        '🎉 Atividade Concluída!',
        '$activityName finalizada! Você ganhou $xpGained XP',
        notificationDetails,
        payload: 'activity_completed',
      );
      debugPrint('Notificação exibida com sucesso');
    } catch (e) {
      debugPrint('Erro ao exibir notificação: $e');
    }
  }

  Future<void> showTimerStartedNotification({
    required String activityName,
    required int minutes,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      debugPrint('Notificações não suportadas na web');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'activity_timer_channel',
      'Timer de Atividades',
      channelDescription: 'Notificações quando o timer de atividades termina',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        1,
        '⏱️ Timer em Andamento',
        '$activityName - $minutes minutos',
        notificationDetails,
        payload: 'timer_running',
      );
    } catch (e) {
      debugPrint('Erro ao exibir notificação de timer: $e');
    }
  }

  Future<void> cancelTimerNotification() async {
    try {
      await _notifications.cancel(1);
    } catch (e) {
      debugPrint('Erro ao cancelar notificação: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Erro ao cancelar todas as notificações: $e');
    }
  }
}
