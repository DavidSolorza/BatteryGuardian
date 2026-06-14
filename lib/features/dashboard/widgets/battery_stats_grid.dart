import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../features/battery/models/battery_info.dart';
import '../../../shared/widgets/app_card.dart';

class BatteryStatsGrid extends StatelessWidget {
  const BatteryStatsGrid({super.key, required this.info});

  final BatteryInfo info;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatTile(
          icon: Icons.bolt,
          label: 'Estado',
          value: BatteryStatusHelper.stateLabel(info.state),
          color: AppColors.primary,
        ),
        _StatTile(
          icon: Icons.thermostat_outlined,
          label: 'Temperatura',
          value: info.temperature != null
              ? '${info.temperature!.toStringAsFixed(1)}°C'
              : 'N/D',
          color: AppColors.warning,
        ),
        _StatTile(
          icon: Icons.electric_bolt_outlined,
          label: 'Voltaje',
          value: info.voltage != null
              ? '${info.voltage!.toStringAsFixed(2)}V'
              : 'N/D',
          color: const Color(0xFF38BDF8),
        ),
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Conectado',
          value: DurationFormatter.format(info.connectedDuration),
          color: AppColors.textSecondary,
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
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
