import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, SettingsProvider>(
      builder: (context, alerts, settings, _) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (alerts.alarmActive) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.critical,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Alarma activa',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.critical,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            alerts.activeAlertMessage ?? '',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: alerts.stopAlarm,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Detener alarma'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.critical,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('Configuración activa', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.battery_alert,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerta al ${settings.alertLevel}%',
                                style: AppTextStyles.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sonido y vibración al alcanzar el nivel objetivo',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.power, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            settings.chargingNotificationsEnabled
                                ? 'Eventos de carga activos'
                                : 'Eventos de carga desactivados',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alerta por temperatura a ${settings.tempThreshold.toStringAsFixed(0)}°C',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Historial reciente', style: AppTextStyles.titleLarge),
                      if (alerts.history.isNotEmpty)
                        TextButton(
                          onPressed: alerts.clearHistory,
                          child: const Text('Limpiar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (alerts.history.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'Sin alertas',
                      message:
                          'Las alertas de batería, temperatura y eventos de carga aparecerán aquí.',
                    )
                  else
                    ...alerts.history.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconForType(record.type),
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.message,
                                      style: AppTextStyles.bodyLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')} · ${record.level}%',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForType(AlertType type) {
    switch (type) {
      case AlertType.highTemperature:
        return Icons.thermostat;
      case AlertType.chargerConnected:
        return Icons.power;
      case AlertType.chargerDisconnected:
        return Icons.power_off;
      case AlertType.chargerReconnected:
        return Icons.power_rounded;
      default:
        return Icons.battery_alert;
    }
  }
}
