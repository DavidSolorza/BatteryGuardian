import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_health_helper.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/battery/models/battery_info.dart';
import '../../../shared/widgets/app_card.dart';

class BatteryStatsGrid extends StatelessWidget {
  const BatteryStatsGrid({
    super.key,
    required this.info,
    this.timeEstimate,
    this.estimateLabel,
    this.drainRate,
  });

  final BatteryInfo info;
  final String? timeEstimate;
  final String? estimateLabel;
  final double? drainRate;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    final aspectRatio = Responsive.gridAspectRatio(context);
    final colors = context.appColors;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        _StatTile(
          icon: Icons.bolt,
          label: 'Estado',
          value: BatteryStatusHelper.stateLabel(info.state),
          color: colors.primary,
        ),
        _StatTile(
          icon: Icons.thermostat_outlined,
          label: 'Temperatura',
          value: info.temperature != null
              ? '${info.temperature!.toStringAsFixed(1)}°C'
              : 'N/D',
          color: colors.warning,
        ),
        _StatTile(
          icon: Icons.electric_bolt_outlined,
          label: 'Voltaje',
          value: info.voltage != null
              ? '${info.voltage!.toStringAsFixed(2)}V'
              : 'N/D',
          color: AppColors.info,
        ),
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Conectado',
          value: DurationFormatter.format(info.connectedDuration),
          color: colors.textSecondary,
        ),
        if (timeEstimate != null)
          _StatTile(
            icon: Icons.schedule,
            label: estimateLabel ?? 'Estimado',
            value: timeEstimate!,
            color: colors.primary,
          ),
        if (drainRate != null)
          _StatTile(
            icon: Icons.trending_down,
            label: 'Consumo',
            value: '${drainRate!.toStringAsFixed(1)}%/h',
            color: colors.warning,
          ),
        _StatTile(
          icon: Icons.favorite_outline,
          label: 'Salud',
          value: BatteryHealthHelper.healthLabel(info.health),
          color: AppColors.info,
        ),
        _StatTile(
          icon: Icons.memory,
          label: 'Tecnología',
          value: BatteryHealthHelper.technologyLabel(info.technology),
          color: colors.textSecondary,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyles.labelSmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: textStyles.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
