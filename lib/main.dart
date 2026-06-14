import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/services/alarm_service.dart';
import 'core/services/background_monitor_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'providers/alerts_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/battery_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E293B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final preferences = await PreferencesService.create();
  final notificationService = NotificationService();
  await notificationService.initialize();

  final alarmService = AlarmService();
  final backgroundMonitor = BackgroundMonitorService();

  if (preferences.backgroundMonitoringEnabled) {
    await backgroundMonitor.start();
  }

  runApp(
    BatteryGuardianApp(
      preferences: preferences,
      notificationService: notificationService,
      alarmService: alarmService,
      backgroundMonitor: backgroundMonitor,
    ),
  );
}

class BatteryGuardianApp extends StatelessWidget {
  const BatteryGuardianApp({
    super.key,
    required this.preferences,
    required this.notificationService,
    required this.alarmService,
    required this.backgroundMonitor,
  });

  final PreferencesService preferences;
  final NotificationService notificationService;
  final AlarmService alarmService;
  final BackgroundMonitorService backgroundMonitor;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            preferences,
            backgroundMonitorService: backgroundMonitor,
          )..refreshServiceStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertsProvider(
            preferences: preferences,
            notificationService: notificationService,
            alarmService: alarmService,
            backgroundMonitorService: backgroundMonitor,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => BatteryProvider(
            preferences: preferences,
            notificationService: notificationService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
            home: preferences.onboardingComplete
                ? const HomeScreen()
                : OnboardingScreen(preferences: preferences),
          );
        },
      ),
    );
  }
}
