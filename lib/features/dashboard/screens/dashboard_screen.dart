import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_care_advisor.dart';
import '../../../core/utils/battery_health_score.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/battery/models/battery_info.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/battery_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/battery_circle_indicator.dart';
import '../widgets/battery_score_card.dart';
import '../widgets/battery_stats_grid.dart';
import '../widgets/care_tip_card.dart';
import '../widgets/health_status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<BatteryProvider, AlertsProvider, SettingsProvider,
        AnalyticsProvider>(
      builder: (context, battery, alerts, settings, analytics, _) {
        if (battery.isLoading) {
          return const DashboardSkeleton();
        }

        if (battery.error != null) {
          return ErrorState(
            message: battery.error!,
            onRetry: battery.retry,
          );
        }

        final info = battery.batteryInfo;
        final health = BatteryStatusHelper.resolveHealthLevel(info);
        final statusColor = AppColors.statusColor(health);
        final colors = context.appColors;
        final textStyles = context.textStyles;
        final isWide = Responsive.isExpanded(context);
        final plugged = BatteryStatusHelper.isPluggedIn(info.state);

        final tip = BatteryCareAdvisor.bestTip(
          info: info,
          alertLevel: settings.alertLevel,
          isPluggedIn: plugged,
        );

        final healthScore = BatteryHealthScore.fromLiveState(
          info: info,
          alertLevel: settings.alertLevel,
          careHabitScore: analytics.data.completedSessionCount > 0
              ? analytics.data.careScore
              : null,
        );

        final timeLeft = BatteryCareAdvisor.estimatedTimeRemaining(
          info: info,
          isPluggedIn: plugged,
          alertLevel: settings.alertLevel,
        );

        final chargeEta = BatteryCareAdvisor.estimatedChargeEta(
          info: info,
          alertLevel: settings.alertLevel,
          chargingStartedAt: battery.chargingStartedAt,
          startLevel: battery.activeSession?.startLevel,
        );

        return RefreshIndicator(
          onRefresh: () async {
            await battery.retry();
            await analytics.refresh();
          },
          color: colors.primary,
          backgroundColor: colors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ResponsiveContent(
                  padding: Responsive.pagePadding(context).copyWith(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MonitoringStatusCard(
                        settings: settings,
                        onRestart: settings.restartBackgroundService,
                      ),
                      const SizedBox(height: 16),
                      if (alerts.alarmActive) ...[
                        _AlarmBanner(alerts: alerts),
                        const SizedBox(height: 16),
                      ],
                      if (isWide)
                        _WideDashboardHeader(
                          info: info,
                          health: health,
                          statusColor: statusColor,
                        )
                      else ...[
                        Center(child: HealthStatusBadge(level: health)),
                        const SizedBox(height: 24),
                        Center(
                          child: BatteryCircleIndicator(
                            level: info.level,
                            statusColor: statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            BatteryStatusHelper.stateLabel(info.state),
                            style: textStyles.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      BatteryScoreCard(healthScore: healthScore),
                      const SizedBox(height: 12),
                      if (tip != null) CareTipCard(tip: tip),
                      const SizedBox(height: 16),
                      BatteryStatsGrid(
                        info: info,
                        timeEstimate: plugged ? chargeEta : timeLeft,
                        estimateLabel: plugged ? 'ETA objetivo' : 'Uso estimado',
                        drainRate: battery.drainRatePerHour,
                      ),
                      const SizedBox(height: 16),
                      _CareHabitsCard(
                        careScore: analytics.data.careScore,
                        sessionCount: analytics.data.completedSessionCount,
                      ),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.flag_outlined,
                                iconColor: colors.primary,
                                title: 'Objetivo de carga',
                                message:
                                    'Te avisaremos al ${settings.alertLevel}% con sonido y vibración',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoCard(
                                icon: Icons.shield_outlined,
                                iconColor: statusColor,
                                title: 'Salud del dispositivo',
                                message: _healthMessage(health),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _InfoCard(
                          icon: Icons.flag_outlined,
                          iconColor: colors.primary,
                          title: 'Objetivo de carga',
                          message:
                              'Te avisaremos al ${settings.alertLevel}% con sonido y vibración',
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.shield_outlined,
                          iconColor: statusColor,
                          title: 'Salud del dispositivo',
                          message: _healthMessage(health),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _healthMessage(BatteryHealthLevel level) {
    switch (level) {
      case BatteryHealthLevel.excellent:
        return 'Tu batería está en condiciones óptimas.';
      case BatteryHealthLevel.normal:
        return 'Funcionamiento normal. Monitoreo activo.';
      case BatteryHealthLevel.warning:
        return 'Atención recomendada. Revisa temperatura o nivel.';
      case BatteryHealthLevel.critical:
        return 'Estado crítico. Desconecta el cargador ahora.';
    }
  }
}

class _CareHabitsCard extends StatelessWidget {
  const _CareHabitsCard({
    required this.careScore,
    required this.sessionCount,
  });

  final int careScore;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Text('Hábitos de carga', style: textStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          if (sessionCount == 0)
            Text(
              'Conecta y desconecta el cargador para ver tu puntuación '
              'de hábitos basada en tus sesiones.',
              style: textStyles.bodyMedium,
            )
          else ...[
            Text(
              'Puntuación histórica: $careScore/100',
              style: textStyles.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _habitMessage(careScore),
              style: textStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _habitMessage(int score) {
    if (score >= 80) {
      return 'Desconectas a tiempo y evitas cargas al 100%. ¡Sigue así!';
    }
    if (score >= 60) {
      return 'Buen progreso. Intenta desconectar entre 70-85% más seguido.';
    }
    return 'Muchas cargas largas o al 100%. Ajusta tu objetivo en Ajustes.';
  }
}

class _WideDashboardHeader extends StatelessWidget {
  const _WideDashboardHeader({
    required this.info,
    required this.health,
    required this.statusColor,
  });

  final BatteryInfo info;
  final BatteryHealthLevel health;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthStatusBadge(level: health),
              const SizedBox(height: 16),
              Text(
                BatteryStatusHelper.stateLabel(info.state),
                style: textStyles.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Monitoreo en tiempo real de tu dispositivo',
                style: textStyles.bodyMedium,
              ),
            ],
          ),
        ),
        BatteryCircleIndicator(
          level: info.level,
          statusColor: statusColor,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textStyles.titleMedium),
                const SizedBox(height: 4),
                Text(message, style: textStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringStatusCard extends StatelessWidget {
  const _MonitoringStatusCard({
    required this.settings,
    required this.onRestart,
  });

  final SettingsProvider settings;
  final Future<void> Function() onRestart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final isActive = settings.serviceRunning;
    final color = isActive ? colors.primary : colors.warning;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.sensors : Icons.sensors_off,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? 'Monitoreo 24/7 activo'
                          : 'Monitoreo inactivo',
                      style: textStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Vigilancia permanente con auto-reinicio'
                          : 'Activa el monitoreo en Ajustes',
                      style: textStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!settings.batteryOptimizationIgnored) ...[
            const SizedBox(height: 12),
            Text(
              'Desactiva la optimización de batería para evitar que Android '
              'detenga el servicio.',
              style: textStyles.bodyMedium.copyWith(color: colors.warning),
            ),
          ],
          if (!isActive && settings.backgroundMonitoringEnabled) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRestart,
              child: const Text('Reactivar monitoreo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.alerts});

  final AlertsProvider alerts;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: colors.critical),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alerts.activeAlertMessage ?? 'Alarma activa',
              style: textStyles.bodyLarge,
            ),
          ),
          FilledButton(
            onPressed: alerts.stopAlarm,
            style: FilledButton.styleFrom(
              backgroundColor: colors.critical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }
}
