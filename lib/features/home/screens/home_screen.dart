import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/battery/models/battery_info.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final BatteryProvider _batteryProvider;
  late final SettingsProvider _settingsProvider;
  BatteryInfo? _lastAlertSnapshot;

  static const _titles = [
    'Dashboard',
    'Historial',
    'Analíticas',
    'Alertas',
    'Ajustes',
  ];

  late final List<Widget> _screens;

  static const _destinations = [
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
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Inicio'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history),
      selectedIcon: Icon(Icons.history),
      label: Text('Historial'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: Text('Analíticas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: Text('Alertas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Ajustes'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const HistoryScreen(),
      const AnalyticsScreen(),
      AlertsScreen(onOpenSettings: () => setState(() => _currentIndex = 4)),
      const SettingsScreen(),
    ];
    WidgetsBinding.instance.addObserver(this);
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
    _batteryProvider.onSessionChanged = () {
      context.read<HistoryProvider>().refresh();
      context.read<AnalyticsProvider>().refresh();
    };
    _batteryProvider.addListener(_evaluateAlerts);
    _settingsProvider.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsProvider.ensureBackgroundMonitoring();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _settingsProvider.ensureBackgroundMonitoring();
      unawaited(_syncBackgroundData());
    }
  }

  Future<void> _syncBackgroundData() async {
    final alerts = context.read<AlertsProvider>();
    await alerts.syncNativeEvents();
    if (!mounted) return;
    await context.read<HistoryProvider>().refresh();
    if (!mounted) return;
    await context.read<AnalyticsProvider>().refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryProvider.removeListener(_evaluateAlerts);
    _settingsProvider.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _batteryProvider.updatePollInterval();
  }

  void _evaluateAlerts() {
    final battery = _batteryProvider.batteryInfo;
    final previous = _lastAlertSnapshot;
    if (previous != null &&
        !battery.hasAlertRelevantChangeFrom(previous)) {
      return;
    }

    _lastAlertSnapshot = battery;
    context.read<AlertsProvider>().evaluate(battery);
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      unawaited(_syncBackgroundData());
    } else if (index == 2) {
      unawaited(_syncBackgroundData());
    } else if (index == 3) {
      context.read<AlertsProvider>().syncNativeEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final useRail = Responsive.useNavigationRail(context);

    return Consumer<AlertsProvider>(
      builder: (context, alerts, _) {
        final appBar = AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConstants.appName, style: textStyles.labelSmall),
              Text(_titles[_currentIndex], style: textStyles.titleLarge),
            ],
          ),
          actions: [
            if (alerts.alarmActive)
              IconButton(
                onPressed: alerts.stopAlarm,
                icon: const Icon(Icons.notifications_active),
                color: colors.critical,
                tooltip: 'Detener alarma',
              ),
          ],
        );

        final body = AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _screens[_currentIndex],
          ),
        );

        if (useRail) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabSelected,
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                  minWidth: 88,
                ),
                VerticalDivider(width: 1, color: colors.divider),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
