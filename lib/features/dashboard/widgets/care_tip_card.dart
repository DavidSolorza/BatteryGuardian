import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_care_advisor.dart';
import '../../../shared/widgets/app_card.dart';

class CareTipCard extends StatelessWidget {
  const CareTipCard({super.key, required this.tip});

  final CareTip tip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final icon = _iconFor(tip.icon);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consejo del momento', style: textStyles.labelLarge),
                const SizedBox(height: 4),
                Text(tip.title, style: textStyles.titleMedium),
                const SizedBox(height: 6),
                Text(tip.message, style: textStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    return switch (name) {
      'thermostat' || 'device_thermostat' => Icons.thermostat,
      'power_off' => Icons.power_off,
      'flag' => Icons.flag_outlined,
      'battery_alert' => Icons.battery_alert,
      'battery_0_bar' => Icons.battery_0_bar,
      'battery_2_bar' => Icons.battery_2_bar,
      'timer' => Icons.timer_outlined,
      'bedtime' => Icons.bedtime_outlined,
      'thumb_up' => Icons.thumb_up_outlined,
      'eco' => Icons.eco_outlined,
      _ => Icons.lightbulb_outline,
    };
  }
}
