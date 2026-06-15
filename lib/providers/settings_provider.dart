import 'package:flutter/foundation.dart';

import '../core/services/background_monitor_service.dart';
import '../core/services/preferences_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(
    this._preferences, {
    BackgroundMonitorService? backgroundMonitorService,
  }) : _backgroundMonitor = backgroundMonitorService ?? BackgroundMonitorService();

  final PreferencesService _preferences;
  final BackgroundMonitorService _backgroundMonitor;

  bool _serviceRunning = false;
  bool _batteryOptimizationIgnored = true;

  int get alertLevel => _preferences.alertLevel;
  bool get soundEnabled => _preferences.soundEnabled;
  bool get vibrationEnabled => _preferences.vibrationEnabled;
  bool get darkTheme => _preferences.darkTheme;
  bool get powerSavingMode => _preferences.powerSavingMode;
  String get customSound => _preferences.customSound;
  double get tempThreshold => _preferences.tempThreshold;
  bool get backgroundMonitoringEnabled =>
      _preferences.backgroundMonitoringEnabled;
  bool get chargingNotificationsEnabled =>
      _preferences.chargingNotificationsEnabled;
  bool get lowBatteryAlertEnabled => _preferences.lowBatteryAlertEnabled;
  int get lowBatteryLevel => _preferences.lowBatteryLevel;
  bool get fullChargeAlertEnabled => _preferences.fullChargeAlertEnabled;
  bool get overchargeAlertEnabled => _preferences.overchargeAlertEnabled;
  bool get quietHoursEnabled => _preferences.quietHoursEnabled;
  int get quietHoursStart => _preferences.quietHoursStart;
  int get quietHoursEnd => _preferences.quietHoursEnd;
  bool get serviceRunning => _serviceRunning;
  bool get batteryOptimizationIgnored => _batteryOptimizationIgnored;

  Future<void> refreshServiceStatus() async {
    _serviceRunning = await _backgroundMonitor.isRunning();
    _batteryOptimizationIgnored =
        await _backgroundMonitor.isBatteryOptimizationIgnored();
    notifyListeners();
  }

  Future<void> setAlertLevel(int value) async {
    await _preferences.setAlertLevel(value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    await _preferences.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _preferences.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    await _preferences.setDarkTheme(value);
    notifyListeners();
  }

  Future<void> setPowerSavingMode(bool value) async {
    await _preferences.setPowerSavingMode(value);
    notifyListeners();
  }

  Future<void> setCustomSound(String value) async {
    await _preferences.setCustomSound(value);
    notifyListeners();
  }

  Future<void> setTempThreshold(double value) async {
    await _preferences.setTempThreshold(value);
    notifyListeners();
  }

  Future<void> setBackgroundMonitoringEnabled(bool value) async {
    await _preferences.setBackgroundMonitoringEnabled(value);
    if (value) {
      await _backgroundMonitor.start();
      await _backgroundMonitor.ensureRunning();
    } else {
      await _backgroundMonitor.stop();
    }
    await refreshServiceStatus();
  }

  Future<void> ensureBackgroundMonitoring() async {
    if (!_preferences.backgroundMonitoringEnabled) {
      await refreshServiceStatus();
      return;
    }
    await _backgroundMonitor.ensureRunning();
    await refreshServiceStatus();
  }

  Future<void> setChargingNotificationsEnabled(bool value) async {
    await _preferences.setChargingNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setLowBatteryAlertEnabled(bool value) async {
    await _preferences.setLowBatteryAlertEnabled(value);
    notifyListeners();
  }

  Future<void> setLowBatteryLevel(int value) async {
    await _preferences.setLowBatteryLevel(value);
    notifyListeners();
  }

  Future<void> setFullChargeAlertEnabled(bool value) async {
    await _preferences.setFullChargeAlertEnabled(value);
    notifyListeners();
  }

  Future<void> setOverchargeAlertEnabled(bool value) async {
    await _preferences.setOverchargeAlertEnabled(value);
    notifyListeners();
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    await _preferences.setQuietHoursEnabled(value);
    notifyListeners();
  }

  Future<void> setQuietHoursStart(int value) async {
    await _preferences.setQuietHoursStart(value);
    notifyListeners();
  }

  Future<void> setQuietHoursEnd(int value) async {
    await _preferences.setQuietHoursEnd(value);
    notifyListeners();
  }

  Future<void> requestBatteryOptimizationExemption() async {
    await _backgroundMonitor.requestBatteryOptimizationExemption();
    await refreshServiceStatus();
  }

  Future<void> restartBackgroundService() async {
    if (_preferences.backgroundMonitoringEnabled) {
      await _backgroundMonitor.start();
      await _backgroundMonitor.ensureRunning();
    }
    await refreshServiceStatus();
  }
}
