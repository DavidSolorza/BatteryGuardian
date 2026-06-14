import 'package:flutter/foundation.dart';

import '../core/services/alarm_service.dart';
import '../core/services/background_monitor_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/battery_status_helper.dart';
import '../features/battery/models/battery_info.dart';

enum AlertType {
  targetLevel,
  highTemperature,
  chargerConnected,
  chargerDisconnected,
  chargerReconnected,
}

class AlertRecord {
  const AlertRecord({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.level,
  });

  final AlertType type;
  final String message;
  final DateTime timestamp;
  final int level;
}

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({
    required PreferencesService preferences,
    required NotificationService notificationService,
    required AlarmService alarmService,
    BackgroundMonitorService? backgroundMonitorService,
  })  : _preferences = preferences,
        _notificationService = notificationService,
        _alarmService = alarmService,
        _backgroundMonitor = backgroundMonitorService ?? BackgroundMonitorService();

  final PreferencesService _preferences;
  final NotificationService _notificationService;
  final AlarmService _alarmService;
  final BackgroundMonitorService _backgroundMonitor;

  final List<AlertRecord> _history = [];
  bool _levelAlertTriggered = false;
  bool _tempAlertTriggered = false;
  bool _alarmActive = false;
  String? _activeAlertMessage;
  bool _backgroundHandlesAlerts = false;

  List<AlertRecord> get history => List.unmodifiable(_history);
  bool get alarmActive => _alarmActive;
  String? get activeAlertMessage => _activeAlertMessage;

  void initialize() {
    _notificationService.onStopAlarmTapped = (_) => stopAlarm();
    _refreshBackgroundState();
  }

  Future<void> _refreshBackgroundState() async {
    _backgroundHandlesAlerts =
        _preferences.backgroundMonitoringEnabled &&
        await _backgroundMonitor.isRunning();
  }

  Future<void> evaluate(BatteryInfo info) async {
    await _refreshBackgroundState();

    if (!BatteryStatusHelper.isCharging(info.state)) {
      _resetLevelTriggers();
    }

    if (_backgroundHandlesAlerts) return;

    await _checkLevelAlert(info);
    await _checkTemperatureAlert(info);
  }

  Future<void> _checkLevelAlert(BatteryInfo info) async {
    if (!BatteryStatusHelper.isCharging(info.state)) return;

    final target = _preferences.alertLevel;
    if (info.level >= target && !_levelAlertTriggered) {
      _levelAlertTriggered = true;
      await _triggerAlert(
        type: AlertType.targetLevel,
        title: '¡Batería al ${info.level}%!',
        body:
            'Alcanzaste el $target% configurado. Desconecta el cargador para prolongar su vida útil.',
        level: info.level,
      );
    }
  }

  Future<void> _checkTemperatureAlert(BatteryInfo info) async {
    final temp = info.temperature;
    if (temp == null) return;

    if (temp >= _preferences.tempThreshold && !_tempAlertTriggered) {
      _tempAlertTriggered = true;
      await _triggerAlert(
        type: AlertType.highTemperature,
        title: 'Temperatura elevada',
        body:
            'La batería alcanzó ${temp.toStringAsFixed(1)}°C. Deja enfriar el dispositivo.',
        level: info.level,
      );
    } else if (temp < _preferences.tempThreshold - 2) {
      _tempAlertTriggered = false;
    }
  }

  void recordChargingEvent({
    required AlertType type,
    required String message,
    required int level,
  }) {
    _history.insert(
      0,
      AlertRecord(
        type: type,
        message: message,
        timestamp: DateTime.now(),
        level: level,
      ),
    );
    if (_history.length > 50) {
      _history.removeLast();
    }
    notifyListeners();
  }

  Future<void> _triggerAlert({
    required AlertType type,
    required String title,
    required String body,
    required int level,
  }) async {
    _activeAlertMessage = body;
    _alarmActive = true;

    _history.insert(
      0,
      AlertRecord(
        type: type,
        message: body,
        timestamp: DateTime.now(),
        level: level,
      ),
    );
    if (_history.length > 50) {
      _history.removeLast();
    }

    await _notificationService.showBatteryAlert(
      id: type.index,
      title: title,
      body: body,
      ongoing: true,
    );

    await _alarmService.start(
      soundEnabled: _preferences.soundEnabled,
      vibrationEnabled: _preferences.vibrationEnabled,
      soundAsset: _soundAssetPath(),
    );

    notifyListeners();
  }

  String _soundAssetPath() {
    final path = _preferences.customSound;
    if (path.startsWith('assets/')) {
      return path.replaceFirst('assets/', '');
    }
    return 'sounds/alarm.wav';
  }

  Future<void> stopAlarm() async {
    _alarmActive = false;
    _activeAlertMessage = null;
    await _alarmService.stop();
    await _backgroundMonitor.stopNativeAlarm();
    await _notificationService.cancelAll();
    notifyListeners();
  }

  void _resetLevelTriggers() {
    _levelAlertTriggered = false;
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}
