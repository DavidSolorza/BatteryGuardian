import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/services/alarm_service.dart';
import '../core/services/background_monitor_service.dart';
import '../core/services/custom_sound_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/battery_health_score.dart';
import '../core/utils/battery_status_helper.dart';
import '../database/sqlite/alert_event_model.dart';
import '../database/sqlite/database_helper.dart';
import '../features/battery/models/battery_info.dart';

enum AlertType {
  targetLevel,
  highTemperature,
  chargerConnected,
  chargerDisconnected,
  chargerReconnected,
  lowBattery,
  fullCharge,
  overcharge,
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
    DatabaseHelper? databaseHelper,
  })  : _preferences = preferences,
        _notificationService = notificationService,
        _alarmService = alarmService,
        _backgroundMonitor = backgroundMonitorService ?? BackgroundMonitorService(),
        _db = databaseHelper ?? DatabaseHelper.instance;

  final PreferencesService _preferences;
  final NotificationService _notificationService;
  final AlarmService _alarmService;
  final BackgroundMonitorService _backgroundMonitor;
  final DatabaseHelper _db;

  static const _maxHistory = 100;

  final List<AlertRecord> _history = [];
  bool _levelAlertTriggered = false;
  bool _tempAlertTriggered = false;
  bool _lowBatteryTriggered = false;
  bool _fullChargeTriggered = false;
  bool _overchargeTriggered = false;
  DateTime? _highLevelSince;
  bool _alarmActive = false;
  String? _activeAlertMessage;
  bool _backgroundHandlesAlerts = false;
  DateTime? _backgroundStateCheckedAt;

  List<AlertRecord> get history => List.unmodifiable(_history);
  bool get alarmActive => _alarmActive;
  String? get activeAlertMessage => _activeAlertMessage;

  void initialize() {
    _notificationService.onStopAlarmTapped = (_) => stopAlarm();
    _refreshBackgroundState();
    loadHistory();
    syncNativeEvents();
  }

  Future<void> loadHistory() async {
    try {
      final events = await _db.getRecentAlertEvents(limit: _maxHistory);
      _history
        ..clear()
        ..addAll(events.map((e) => e.toRecord()));
      notifyListeners();
    } catch (_) {
      // Keep in-memory history if DB is unavailable.
    }
  }

  Future<void> syncNativeEvents() async {
    try {
      final raw = await _backgroundMonitor.drainNativeAlertEvents();
      final list = jsonDecode(raw) as List<dynamic>;
      if (list.isEmpty) return;

      var changed = false;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final typeIndex = map['type'] as int;
        if (typeIndex < 0 || typeIndex >= AlertType.values.length) continue;

        final level = map['level'] as int;
        if (level <= 0 || level > 100) continue;

        final record = AlertRecord(
          type: AlertType.values[typeIndex],
          message: map['message'] as String,
          level: level,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            map['timestamp'] as int,
          ),
        );

        if (_hasSimilarRecord(record)) continue;

        await _db.insertAlertEvent(AlertEventModel.fromRecord(record));
        _history.insert(0, record);
        changed = true;
      }

      while (_history.length > _maxHistory) {
        _history.removeLast();
      }

      if (changed) notifyListeners();
    } catch (_) {
      // Native queue unavailable on this platform.
    }
  }

  bool _hasSimilarRecord(AlertRecord record) {
    return _history.any(
      (existing) =>
          existing.type == record.type &&
          existing.message == record.message &&
          existing.level == record.level &&
          existing.timestamp
                  .difference(record.timestamp)
                  .inSeconds
                  .abs() <
              30,
    );
  }

  Future<void> _persistRecord(AlertRecord record) async {
    _history.insert(0, record);
    while (_history.length > _maxHistory) {
      _history.removeLast();
    }
    try {
      await _db.insertAlertEvent(AlertEventModel.fromRecord(record));
    } catch (_) {
      // History remains in memory.
    }
    notifyListeners();
  }

  Future<void> _refreshBackgroundState({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _backgroundStateCheckedAt != null &&
        now.difference(_backgroundStateCheckedAt!) <
            const Duration(seconds: 30)) {
      return;
    }

    _backgroundStateCheckedAt = now;
    _backgroundHandlesAlerts =
        _preferences.backgroundMonitoringEnabled &&
        await _backgroundMonitor.isRunning();
  }

  Future<void> evaluate(BatteryInfo info) async {
    await _refreshBackgroundState();

    if (!BatteryStatusHelper.isCharging(info.state)) {
      _resetLevelTriggers();
    }

    if (_backgroundHandlesAlerts) {
      final nativeActive = await _backgroundMonitor.isNativeAlarmActive();
      if (nativeActive && !_alarmActive) {
        _alarmActive = true;
        notifyListeners();
      } else if (!nativeActive && _alarmActive) {
        await stopAlarm();
      }
      return;
    }

    await _checkLevelAlert(info);
    await _checkTemperatureAlert(info);
    await _checkLowBatteryAlert(info);
    await _checkFullChargeAlert(info);
    await _checkOverchargeAlert(info);
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
    if (_backgroundHandlesAlerts) return;

    final record = AlertRecord(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      level: level,
    );
    if (_hasSimilarRecord(record)) return;
    unawaited(_persistRecord(record));
  }

  Future<void> _checkLowBatteryAlert(BatteryInfo info) async {
    if (!_preferences.lowBatteryAlertEnabled) return;
    if (BatteryStatusHelper.isPluggedIn(info.state)) {
      _lowBatteryTriggered = false;
      return;
    }

    if (info.level <= 0) return;

    final threshold = _preferences.lowBatteryLevel;
    if (info.level <= threshold && !_lowBatteryTriggered) {
      _lowBatteryTriggered = true;
      await _triggerAlert(
        type: AlertType.lowBattery,
        title: 'Batería baja',
        body:
            'Queda ${info.level}% de batería. Conecta el cargador pronto.',
        level: info.level,
      );
    } else if (info.level > threshold + 5) {
      _lowBatteryTriggered = false;
    }
  }

  Future<void> _checkFullChargeAlert(BatteryInfo info) async {
    if (!_preferences.fullChargeAlertEnabled) return;

    if (!BatteryStatusHelper.isPluggedIn(info.state)) {
      _fullChargeTriggered = false;
      return;
    }

    if (info.level >= 100 && !_fullChargeTriggered) {
      _fullChargeTriggered = true;
      await _triggerAlert(
        type: AlertType.fullCharge,
        title: 'Carga completa',
        body: 'La batería llegó al 100%. Puedes desconectar el cargador.',
        level: info.level,
      );
    }
  }

  Future<void> _checkOverchargeAlert(BatteryInfo info) async {
    if (!_preferences.overchargeAlertEnabled) return;

    if (!BatteryStatusHelper.isPluggedIn(info.state)) {
      _highLevelSince = null;
      _overchargeTriggered = false;
      return;
    }

    if (info.level >= 95) {
      _highLevelSince ??= DateTime.now();
      final pluggedMinutes =
          DateTime.now().difference(_highLevelSince!).inMinutes;
      if (pluggedMinutes >= 30 && !_overchargeTriggered) {
        _overchargeTriggered = true;
        await _triggerAlert(
          type: AlertType.overcharge,
          title: 'Carga prolongada',
          body:
              'Llevas $pluggedMinutes min conectado al ${info.level}%. Desconecta para cuidar la batería.',
          level: info.level,
        );
      }
    } else {
      _highLevelSince = null;
      _overchargeTriggered = false;
    }
  }

  Future<void> testAlarm() async {
    await _alarmService.preview(
      soundPath: _soundPath(),
      soundEnabled: _preferences.soundEnabled,
      vibrationEnabled: _preferences.vibrationEnabled,
    );
  }

  Future<void> _triggerAlert({
    required AlertType type,
    required String title,
    required String body,
    required int level,
  }) async {
    _activeAlertMessage = body;
    _alarmActive = true;

    await _persistRecord(
      AlertRecord(
        type: type,
        message: body,
        timestamp: DateTime.now(),
        level: level,
      ),
    );

    await _notificationService.showBatteryAlert(
      id: type.index,
      title: title,
      body: body,
      ongoing: true,
    );

    final quiet = QuietHoursHelper.isActive(
      enabled: _preferences.quietHoursEnabled,
      startHour: _preferences.quietHoursStart,
      endHour: _preferences.quietHoursEnd,
    );

    await _alarmService.start(
      soundEnabled: _preferences.soundEnabled && !quiet,
      vibrationEnabled: _preferences.vibrationEnabled && !quiet,
      soundPath: _soundPath(),
    );
  }

  String _soundPath() {
    final path = _preferences.customSound;
    if (path.startsWith('assets/') || CustomSoundService.isLocalPath(path)) {
      return path;
    }
    return 'assets/sounds/alarm.wav';
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

  Future<void> clearHistory() async {
    _history.clear();
    try {
      await _db.deleteAllAlertEvents();
    } catch (_) {
      // Cleared in memory only.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}
