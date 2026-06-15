import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_content.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, SettingsProvider>(
      builder: (context, alerts, settings, _) {
        final colors = context.appColors;
        final textStyles = context.textStyles;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (alerts.alarmActive) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: colors.critical,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Alarma activa',
                                  style: textStyles.titleLarge.copyWith(
                                    color: colors.critical,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alerts.activeAlertMessage ?? '',
                              style: textStyles.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: alerts.stopAlarm,
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('Detener alarma'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.critical,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('Configuración activa', style: textStyles.titleLarge),
                    if (onOpenSettings != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onOpenSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Ir a ajustes de alertas'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.battery_alert, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alerta al ${settings.alertLevel}%',
                                  style: textStyles.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sonido y vibración al alcanzar el nivel objetivo',
                                  style: textStyles.bodyMedium,
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
                          Icon(Icons.power, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.chargingNotificationsEnabled
                                  ? 'Eventos de carga activos'
                                  : 'Eventos de carga desactivados',
                              style: textStyles.titleMedium,
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
                          Icon(Icons.battery_0_bar, color: colors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.lowBatteryAlertEnabled
                                  ? 'Batería baja al ${settings.lowBatteryLevel}%'
                                  : 'Alerta de batería baja desactivada',
                              style: textStyles.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.thermostat, color: colors.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Alerta por temperatura a ${settings.tempThreshold.toStringAsFixed(0)}°C',
                              style: textStyles.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Historial reciente', style: textStyles.titleLarge),
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
                                  color: colors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.message,
                                        style: textStyles.bodyLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('d MMM, HH:mm', 'es').format(record.timestamp)} · ${record.level}%',
                                        style: textStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
      case AlertType.lowBattery:
        return Icons.battery_0_bar;
      case AlertType.fullCharge:
        return Icons.battery_full;
      case AlertType.overcharge:
        return Icons.timer;
      default:
        return Icons.battery_alert;
    }
  }
}
