import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../database/sqlite/charging_session_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../shared/widgets/app_card.dart';

class RecentSessionsCard extends StatelessWidget {
  const RecentSessionsCard({
    super.key,
    required this.sessions,
  });

  final List<ChargingSessionModel> sessions;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.appColors;

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimas cargas', style: textStyles.titleLarge),
        const SizedBox(height: 12),
        ...sessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.battery_charging_full, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.startLevel}% → ${session.endLevel ?? '?'}%',
                          style: textStyles.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormatter.formatDate(session.startTime)} · ${DurationFormatter.format(session.duration)}',
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
    );
  }
}
