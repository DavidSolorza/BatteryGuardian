import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../core/utils/charge_metrics.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../shared/widgets/app_card.dart';

class LiveChargeCard extends StatelessWidget {
  const LiveChargeCard({
    super.key,
    required this.stats,
  });

  final LiveChargeStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    if (!stats.isActive) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.battery_std_outlined, color: colors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sin carga activa', style: textStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Conecta el cargador para ver estadísticas en tiempo real.',
                    style: textStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final progress = (stats.currentLevel / stats.targetLevel).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: colors.primary),
              const SizedBox(width: 10),
              Text('Carga en vivo', style: textStyles.titleLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  BatteryStatusHelper.stateLabel(stats.state),
                  style: textStyles.labelLarge.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.cardElevated,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.currentLevel}% → objetivo ${stats.targetLevel}%',
            style: textStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          _MetricRow(
            icon: Icons.play_arrow,
            label: 'Inicio',
            value: '${stats.startLevel}%',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.trending_up,
            label: 'Ganancia',
            value: stats.levelGain >= 0
                ? '+${stats.levelGain}%'
                : '${stats.levelGain}%',
            valueColor: stats.levelGain >= 0 ? colors.primary : colors.warning,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.timer_outlined,
            label: 'Tiempo conectado',
            value: DurationFormatter.format(stats.duration),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.speed,
            label: 'Velocidad',
            value: stats.chargeRatePerHour > 0.1
                ? '${stats.chargeRatePerHour.toStringAsFixed(1)}%/h'
                : 'Calculando...',
          ),
          if (stats.estimatedMinutesToTarget != null) ...[
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.flag_outlined,
              label: 'ETA al ${stats.targetLevel}%',
              value: DurationFormatter.format(
                Duration(minutes: stats.estimatedMinutesToTarget!),
              ),
              valueColor: AppColors.info,
            ),
          ],
          if (stats.temperature != null) ...[
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.thermostat_outlined,
              label: 'Temperatura',
              value: '${stats.temperature!.toStringAsFixed(1)}°C',
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: textStyles.bodyMedium)),
        Text(
          value,
          style: textStyles.titleMedium.copyWith(
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
