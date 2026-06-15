import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_health_score.dart';
import '../../../shared/widgets/app_card.dart';

class BatteryScoreCard extends StatelessWidget {
  const BatteryScoreCard({super.key, required this.healthScore});

  final BatteryHealthScore healthScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final scoreColor = _scoreColor(healthScore.score, colors);

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: healthScore.score / 100,
                  strokeWidth: 7,
                  backgroundColor: colors.cardElevated,
                  color: scoreColor,
                ),
                Text(
                  '${healthScore.score}',
                  style: textStyles.titleLarge.copyWith(color: scoreColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Puntuación de cuidado', style: textStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  healthScore.label,
                  style: textStyles.titleLarge.copyWith(color: scoreColor),
                ),
                const SizedBox(height: 4),
                Text(healthScore.detail, style: textStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int score, AppColorScheme colors) {
    if (score >= 85) return colors.primary;
    if (score >= 70) return colors.primary.withValues(alpha: 0.8);
    if (score >= 50) return colors.warning;
    return colors.critical;
  }
}
