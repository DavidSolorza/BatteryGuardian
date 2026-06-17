import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../home/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.preferences});

  final PreferencesService preferences;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _enableMonitoring = true;
  bool _requestBatteryOpt = true;

  static const _infoPages = [
    _OnboardingPage(
      icon: Icons.battery_charging_full,
      title: 'Dashboard',
      description:
          'Monitorea nivel, temperatura y voltaje en tiempo real. Recibe consejos para cuidar tu batería.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Alertas inteligentes',
      description:
          'Nivel objetivo, temperatura, batería baja, carga completa y sobrecarga. ¡Alarma full-screen con sonido y vibración!',
    ),
    _OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'Analíticas e historial',
      description:
          'Gráficas semanales/mensuales, duración de cargas y puntuación de hábitos para optimizar el uso.',
    ),
    _OnboardingPage(
      icon: Icons.explore_outlined,
      title: 'Navegación',
      description:
          '5 secciones: Inicio, Historial, Analíticas, Alertas y Ajustes. Desliza entre pestañas para explorar.',
    ),
  ];

  int get _totalPages => _infoPages.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({bool enableMonitoring = false}) async {
    if (enableMonitoring && mounted) {
      final settings = context.read<SettingsProvider>();
      if (!settings.backgroundMonitoringEnabled) {
        await settings.setBackgroundMonitoringEnabled(true);
      } else {
        await settings.ensureBackgroundMonitoring();
      }
      if (_requestBatteryOpt && !settings.batteryOptimizationIgnored) {
        await settings.requestBatteryOptimizationExemption();
      }
    }

    await widget.preferences.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final maxWidth = Responsive.isExpanded(context) ? 560.0 : double.infinity;
    final isSetupPage = _currentPage == _infoPages.length;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _complete(),
                  child: Text('Omitir', style: textStyles.bodyLarge),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _totalPages,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemBuilder: (context, index) {
                        if (index < _infoPages.length) {
                          return _infoPages[index];
                        }
                        return _SetupPage(
                          enableMonitoring: _enableMonitoring,
                          requestBatteryOpt: _requestBatteryOpt,
                          onMonitoringChanged: (value) =>
                              setState(() => _enableMonitoring = value),
                          onBatteryOptChanged: (value) =>
                              setState(() => _requestBatteryOpt = value),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colors.primary
                          : colors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_currentPage < _totalPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _complete(enableMonitoring: _enableMonitoring);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isSetupPage
                          ? 'Activar y comenzar'
                          : _currentPage < _totalPages - 1
                              ? 'Continuar'
                              : 'Comenzar',
                      style: textStyles.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppConstants.appName, style: textStyles.labelSmall),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, size: 56, color: colors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: textStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  const _SetupPage({
    required this.enableMonitoring,
    required this.requestBatteryOpt,
    required this.onMonitoringChanged,
    required this.onBatteryOptChanged,
  });

  final bool enableMonitoring;
  final bool requestBatteryOpt;
  final ValueChanged<bool> onMonitoringChanged;
  final ValueChanged<bool> onBatteryOptChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(Icons.shield_outlined, size: 56, color: colors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Configuración inicial',
            style: textStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Activa el monitoreo 24/7 para registrar cargas y recibir alertas '
            'aunque cierres la app.',
            style: textStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Monitoreo permanente', style: textStyles.titleMedium),
            subtitle: Text(
              'Servicio en segundo plano con alertas y historial',
              style: textStyles.bodyMedium,
            ),
            value: enableMonitoring,
            onChanged: onMonitoringChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Excluir de optimización',
              style: textStyles.titleMedium,
            ),
            subtitle: Text(
              'Evita que Android detenga el monitoreo',
              style: textStyles.bodyMedium,
            ),
            value: requestBatteryOpt,
            onChanged: enableMonitoring ? onBatteryOptChanged : null,
          ),
        ],
      ),
    );
  }
}
