import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/battery_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/battery_circle_indicator.dart';
import '../widgets/battery_stats_grid.dart';
import '../widgets/health_status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<BatteryProvider, AlertsProvider, SettingsProvider>(
      builder: (context, battery, alerts, settings, _) {
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

        return RefreshIndicator(
          onRefresh: battery.retry,
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MonitoringStatusCard(settings: settings),
                    const SizedBox(height: 16),
                    if (alerts.alarmActive) ...[
                      _AlarmBanner(alerts: alerts),
                      const SizedBox(height: 16),
                    ],
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
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 28),
                    BatteryStatsGrid(info: info),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Objetivo de carga',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Te avisaremos al ${settings.alertLevel}% con sonido y vibración',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: statusColor,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Salud del dispositivo',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _healthMessage(health),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
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

class _MonitoringStatusCard extends StatelessWidget {
  const _MonitoringStatusCard({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final isActive = settings.serviceRunning;
    final color = isActive ? AppColors.primary : AppColors.warning;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                      ? 'Monitoreo en segundo plano'
                      : 'Monitoreo limitado',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Detectando carga, desconexión y nivel objetivo'
                      : 'Activa el monitoreo permanente en Ajustes',
                  style: AppTextStyles.bodyMedium,
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
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.alerts});

  final AlertsProvider alerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.critical),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alerts.activeAlertMessage ?? 'Alarma activa',
              style: AppTextStyles.bodyLarge,
            ),
          ),
          FilledButton(
            onPressed: alerts.stopAlarm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }
}
