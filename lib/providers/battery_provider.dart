import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/services/battery_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/preferences_service.dart';
import '../core/utils/battery_drain_tracker.dart';
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
  VoidCallback? onSessionChanged;

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
  List<DrainSample> _drainSamples = [];

  BatteryInfo get batteryInfo => _batteryInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get chargingStartedAt => _chargingStartedAt;
  ChargingSessionModel? get activeSession => _activeSession;
  double? get drainRatePerHour {
    if (BatteryStatusHelper.isPluggedIn(_batteryInfo.state)) return null;
    return BatteryDrainTracker.ratePerHour(_drainSamples);
  }

  void setChargingEventCallback(
    void Function(AlertType type, String message, int level) callback,
  ) {
    _onChargingEvent = callback;
  }

  Future<void> initialize() async {
    try {
      await _refresh();
      await _db.closeStaleActiveSessions(
        isPluggedIn: BatteryStatusHelper.isPluggedIn(_batteryInfo.state),
        currentLevel: _batteryInfo.level,
      );

      _activeSession = await _db.getActiveSession();
      if (_activeSession != null) {
        _chargingStartedAt = _activeSession!.startTime;
      }

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

      var info = await _batteryService.fetchBatteryInfo(
        connectedDuration: connectedDuration,
        temperatureSamples: _sessionTemperatures,
      );

      if (info.level <= 0 || info.level > 100) {
        info = info.copyWith(level: _batteryInfo.level);
      }

      await _handleChargingStateChange(info);
      final previous = _batteryInfo;
      _batteryInfo = info;
      _error = null;
      await _handleChargingSession(info);

      if (!BatteryStatusHelper.isPluggedIn(info.state)) {
        _drainSamples = BatteryDrainTracker.addSample(
          _drainSamples,
          info.level,
          DateTime.now(),
        );
      } else {
        _drainSamples = [];
      }

      if (previous.hasUiChangedFrom(info)) {
        notifyListeners();
      }
    } catch (e) {
      if (_error != 'Error al leer datos de batería') {
        _error = 'Error al leer datos de batería';
        notifyListeners();
      }
    }
  }

  Future<void> _handleChargingStateChange(BatteryInfo info) async {
    final isCharging = BatteryStatusHelper.isCharging(info.state);
    final backgroundOn = _preferences?.backgroundMonitoringEnabled ?? false;

    if (_wasCharging != null && isCharging != _wasCharging) {
      if (isCharging) {
        final wasDisconnected = _disconnectedInCycle;
        final title = wasDisconnected
            ? 'Cargador reconectado'
            : 'Cargador conectado';
        final body = 'Monitoreando carga desde ${info.level}%';
        _disconnectedInCycle = false;

        if (!backgroundOn &&
            (_preferences?.chargingNotificationsEnabled ?? true)) {
          await _notificationService?.showChargingEvent(
            title: title,
            body: body,
          );
        }
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
        if (!backgroundOn &&
            (_preferences?.chargingNotificationsEnabled ?? true)) {
          await _notificationService?.showChargingEvent(
            title: 'Cargador desconectado',
            body: body,
          );
        }
        _onChargingEvent?.call(
          AlertType.chargerDisconnected,
          body,
          info.level,
        );
      }
    }

    _wasCharging = isCharging;
  }

  Future<void> _handleChargingSession(BatteryInfo info) async {
    final isPluggedIn = BatteryStatusHelper.isPluggedIn(info.state);
    var sessionChanged = false;

    if (isPluggedIn) {
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
        sessionChanged = true;
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

      final durationMinutes = duration.inSeconds <= 0
          ? 0
          : (duration.inSeconds / 60).ceil();

      final completed = _activeSession!.copyWith(
        endTime: endTime,
        endLevel: info.level,
        avgTemperature: avgTemp,
        durationMinutes: durationMinutes,
      );

      await _db.updateSession(completed);
      _activeSession = null;
      _chargingStartedAt = null;
      _sessionTemperatures = [];
      sessionChanged = true;
    }

    if (sessionChanged) {
      onSessionChanged?.call();
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
