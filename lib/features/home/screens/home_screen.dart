import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/battery_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final BatteryProvider _batteryProvider;
  late final SettingsProvider _settingsProvider;

  static const _titles = [
    'Dashboard',
    'Historial',
    'Analíticas',
    'Alertas',
    'Ajustes',
  ];

  final _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _batteryProvider = context.read<BatteryProvider>();
    _settingsProvider = context.read<SettingsProvider>();
    final alerts = context.read<AlertsProvider>();

    _batteryProvider.setChargingEventCallback(
      (type, message, level) => alerts.recordChargingEvent(
        type: type,
        message: message,
        level: level,
      ),
    );
    _batteryProvider.addListener(_evaluateAlerts);
    _settingsProvider.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsProvider.refreshServiceStatus();
      _settingsProvider.requestBatteryOptimizationExemption();
    });
  }

  @override
  void dispose() {
    _batteryProvider.removeListener(_evaluateAlerts);
    _settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _batteryProvider.updatePollInterval();
  }

  void _evaluateAlerts() {
    final battery = context.read<BatteryProvider>().batteryInfo;
    context.read<AlertsProvider>().evaluate(battery);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, alerts, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.labelSmall,
                ),
                Text(_titles[_currentIndex], style: AppTextStyles.titleLarge),
              ],
            ),
            actions: [
              if (alerts.alarmActive)
                IconButton(
                  onPressed: alerts.stopAlarm,
                  icon: const Icon(Icons.notifications_active),
                  color: Colors.redAccent,
                  tooltip: 'Detener alarma',
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[_currentIndex],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              if (index == 1) {
                context.read<HistoryProvider>().refresh();
              } else if (index == 2) {
                context.read<AnalyticsProvider>().refresh();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history),
                label: 'Historial',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Analíticas',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: 'Alertas',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Ajustes',
              ),
            ],
          ),
        );
      },
    );
  }
}
