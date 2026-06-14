abstract final class AppConstants {
  static const String appName = 'Battery Guardian';
  static const String dbName = 'battery_guardian.db';
  static const int dbVersion = 1;

  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefAlertLevel = 'alert_level';
  static const String prefSoundEnabled = 'sound_enabled';
  static const String prefVibrationEnabled = 'vibration_enabled';
  static const String prefDarkTheme = 'dark_theme';
  static const String prefPowerSavingMode = 'power_saving_mode';
  static const String prefCustomSound = 'custom_sound';
  static const String prefTempThreshold = 'temp_threshold';
  static const String prefBackgroundMonitoring = 'background_monitoring_enabled';
  static const String prefChargingNotifications = 'charging_notifications_enabled';

  static const int defaultAlertLevel = 80;
  static const double defaultTempThreshold = 40.0;
  static const Duration batteryPollInterval = Duration(seconds: 5);
  static const Duration batteryPollIntervalPowerSaving = Duration(seconds: 15);
  static const Duration alarmRepeatInterval = Duration(seconds: 3);

  static const List<int> alertThresholds = [70, 75, 80, 85, 90, 95, 100];

  static const String batteryChannel = 'com.batteryguardian/battery';
  static const String notificationChannelId = 'battery_alerts';
  static const String notificationChannelName = 'Alertas de Batería';
  static const String notificationEventsChannelId = 'battery_events';
  static const String notificationEventsChannelName = 'Eventos de Carga';
}
