import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/battery_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/battery_status_helper.dart';
import '../database/sqlite/charging_session_model.dart';
import '../database/sqlite/database_helper.dart';
import '../features/battery/models/battery_info.dart';
import 'alerts_provider.dart';

class BatteryProvider extends ChangeNotifier {
  BatteryProvider({
    BatteryService? batteryService,
    DatabaseHelper? databaseHelper,
    PreferencesService? preferences,
    NotificationService? notificationService,
    void Function(AlertType type, String message, int level)? onChargingEvent,
  })  : _batteryService = batteryService ?? BatteryService(),
        _db = databaseHelper ?? DatabaseHelper.instance,
        _preferences = preferences,
        _notificationService = notificationService,
        _onChargingEvent = onChargingEvent;

  final BatteryService _batteryService;
  final DatabaseHelper _db;
  final PreferencesService? _preferences;
  final NotificationService? _notificationService;
  void Function(AlertType type, String message, int level)? _onChargingEvent;

  BatteryInfo _batteryInfo = BatteryInfo.initial();
  bool _isLoading = true;
  String? _error;
  DateTime? _chargingStartedAt;
  ChargingSessionModel? _activeSession;
  List<double> _sessionTemperatures = [];
  Timer? _pollTimer;
  StreamSubscription<BatteryState>? _stateSubscription;
  bool? _wasCharging;
  bool _disconnectedInCycle = false;

  BatteryInfo get batteryInfo => _batteryInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get chargingStartedAt => _chargingStartedAt;
  ChargingSessionModel? get activeSession => _activeSession;

  void setChargingEventCallback(
    void Function(AlertType type, String message, int level) callback,
  ) {
    _onChargingEvent = callback;
  }

  Future<void> initialize() async {
    try {
      _activeSession = await _db.getActiveSession();
      if (_activeSession != null) {
        _chargingStartedAt = _activeSession!.startTime;
      }

      await _refresh();
      _stateSubscription =
          _batteryService.onBatteryStateChanged.listen((_) => _refresh());
      _restartPollTimer();
    } catch (e) {
      _error = 'No se pudo iniciar el monitoreo de batería';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updatePollInterval() {
    _restartPollTimer();
  }

  void _restartPollTimer() {
    _pollTimer?.cancel();
    final interval = _preferences?.powerSavingMode == true
        ? AppConstants.batteryPollIntervalPowerSaving
        : AppConstants.batteryPollInterval;
    _pollTimer = Timer.periodic(interval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final connectedDuration = _chargingStartedAt != null
          ? DateTime.now().difference(_chargingStartedAt!)
          : Duration.zero;

      final info = await _batteryService.fetchBatteryInfo(
        connectedDuration: connectedDuration,
        temperatureSamples: _sessionTemperatures,
      );

      await _handleChargingStateChange(info);
      _batteryInfo = info;
      _error = null;
      await _handleChargingSession(info);
      notifyListeners();
    } catch (e) {
      _error = 'Error al leer datos de batería';
      notifyListeners();
    }
  }

  Future<void> _handleChargingStateChange(BatteryInfo info) async {
    final isCharging = BatteryStatusHelper.isCharging(info.state);
    final backgroundOn = _preferences?.backgroundMonitoringEnabled ?? false;

    if (_wasCharging != null && isCharging != _wasCharging) {
      if (!backgroundOn &&
          (_preferences?.chargingNotificationsEnabled ?? true)) {
        if (isCharging) {
          final wasDisconnected = _disconnectedInCycle;
          final title = wasDisconnected
              ? 'Cargador reconectado'
              : 'Cargador conectado';
          final body = 'Monitoreando carga desde ${info.level}%';
          _disconnectedInCycle = false;
          await _notificationService?.showChargingEvent(
            title: title,
            body: body,
          );
          _onChargingEvent?.call(
            wasDisconnected
                ? AlertType.chargerReconnected
                : AlertType.chargerConnected,
            body,
            info.level,
          );
        } else {
          _disconnectedInCycle = true;
          final body = 'Nivel actual: ${info.level}%';
          await _notificationService?.showChargingEvent(
            title: 'Cargador desconectado',
            body: body,
          );
          _onChargingEvent?.call(
            AlertType.chargerDisconnected,
            body,
            info.level,
          );
        }
      } else if (!isCharging) {
        _disconnectedInCycle = true;
      } else {
        _disconnectedInCycle = false;
      }
    }

    _wasCharging = isCharging;
  }

  Future<void> _handleChargingSession(BatteryInfo info) async {
    final isCharging = BatteryStatusHelper.isCharging(info.state);

    if (isCharging) {
      if (_chargingStartedAt == null) {
        _chargingStartedAt = DateTime.now();
        _sessionTemperatures = [];
        if (info.temperature != null) {
          _sessionTemperatures.add(info.temperature!);
        }

        final session = ChargingSessionModel(
          startTime: _chargingStartedAt!,
          startLevel: info.level,
        );
        final id = await _db.insertSession(session);
        _activeSession = session.copyWith(id: id);
      } else if (info.temperature != null) {
        _sessionTemperatures.add(info.temperature!);
      }
    } else if (_chargingStartedAt != null && _activeSession != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_chargingStartedAt!);
      final avgTemp = _sessionTemperatures.isEmpty
          ? info.temperature
          : _sessionTemperatures.reduce((a, b) => a + b) /
              _sessionTemperatures.length;

      final completed = _activeSession!.copyWith(
        endTime: endTime,
        endLevel: info.level,
        avgTemperature: avgTemp,
        durationMinutes: duration.inMinutes,
      );

      await _db.updateSession(completed);
      _activeSession = null;
      _chargingStartedAt = null;
      _sessionTemperatures = [];
    }
  }

  Future<void> retry() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _refresh();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
