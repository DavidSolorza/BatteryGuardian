import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final accent = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const Spacer(),
          Text(label, style: textStyles.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: textStyles.titleLarge),
        ],
      ),
    );
  }
}
