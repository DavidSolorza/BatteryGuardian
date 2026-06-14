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
    } else {
      await _backgroundMonitor.stop();
    }
    await refreshServiceStatus();
  }

  Future<void> setChargingNotificationsEnabled(bool value) async {
    await _preferences.setChargingNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> requestBatteryOptimizationExemption() async {
    await _backgroundMonitor.requestBatteryOptimizationExemption();
    await refreshServiceStatus();
  }

  Future<void> restartBackgroundService() async {
    if (_preferences.backgroundMonitoringEnabled) {
      await _backgroundMonitor.start();
    }
    await refreshServiceStatus();
  }
}
