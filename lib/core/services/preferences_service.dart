import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(AppConstants.prefOnboardingComplete, value);

  int get alertLevel =>
      _prefs.getInt(AppConstants.prefAlertLevel) ??
      AppConstants.defaultAlertLevel;

  Future<void> setAlertLevel(int value) =>
      _prefs.setInt(AppConstants.prefAlertLevel, value);

  bool get soundEnabled =>
      _prefs.getBool(AppConstants.prefSoundEnabled) ?? true;

  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(AppConstants.prefSoundEnabled, value);

  bool get vibrationEnabled =>
      _prefs.getBool(AppConstants.prefVibrationEnabled) ?? true;

  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(AppConstants.prefVibrationEnabled, value);

  bool get darkTheme => _prefs.getBool(AppConstants.prefDarkTheme) ?? true;

  Future<void> setDarkTheme(bool value) =>
      _prefs.setBool(AppConstants.prefDarkTheme, value);

  bool get powerSavingMode =>
      _prefs.getBool(AppConstants.prefPowerSavingMode) ?? false;

  Future<void> setPowerSavingMode(bool value) =>
      _prefs.setBool(AppConstants.prefPowerSavingMode, value);

  String get customSound =>
      _prefs.getString(AppConstants.prefCustomSound) ?? 'assets/sounds/alarm.wav';

  Future<void> setCustomSound(String value) =>
      _prefs.setString(AppConstants.prefCustomSound, value);

  double get tempThreshold =>
      _prefs.getDouble(AppConstants.prefTempThreshold) ??
      AppConstants.defaultTempThreshold;

  Future<void> setTempThreshold(double value) =>
      _prefs.setDouble(AppConstants.prefTempThreshold, value);

  bool get backgroundMonitoringEnabled =>
      _prefs.getBool(AppConstants.prefBackgroundMonitoring) ?? true;

  Future<void> setBackgroundMonitoringEnabled(bool value) =>
      _prefs.setBool(AppConstants.prefBackgroundMonitoring, value);

  bool get chargingNotificationsEnabled =>
      _prefs.getBool(AppConstants.prefChargingNotifications) ?? true;

  Future<void> setChargingNotificationsEnabled(bool value) =>
      _prefs.setBool(AppConstants.prefChargingNotifications, value);
}
