import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Alertas de nivel de batería y temperatura',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const eventsChannel = AndroidNotificationChannel(
      AppConstants.notificationEventsChannelId,
      AppConstants.notificationEventsChannelName,
      description: 'Conexión y desconexión del cargador',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(eventsChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  void Function(String? payload)? onStopAlarmTapped;

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'stop_alarm') {
      onStopAlarmTapped?.call(response.payload);
    }
  }

  Future<void> showBatteryAlert({
    required int id,
    required String title,
    required String body,
    bool ongoing = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Alertas de nivel de batería y temperatura',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: ongoing,
      autoCancel: !ongoing,
      fullScreenIntent: ongoing,
      category: AndroidNotificationCategory.alarm,
      actions: ongoing
          ? [
              const AndroidNotificationAction(
                'stop_alarm',
                'Detener alarma',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: ongoing ? 'stop_alarm' : null,
    );
  }

  Future<void> showChargingEvent({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationEventsChannelId,
      AppConstants.notificationEventsChannelName,
      channelDescription: 'Eventos de conexión del cargador',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
