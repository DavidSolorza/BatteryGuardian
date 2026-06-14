import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../database/sqlite/charging_session_model.dart';
import '../../../shared/widgets/app_card.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({super.key, required this.session});

  final ChargingSessionModel session;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatDate(session.startTime),
                style: AppTextStyles.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DurationFormatter.format(session.duration),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.schedule,
            label: 'Inicio',
            value: DateFormatter.formatTime(session.startTime),
          ),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.schedule_outlined,
            label: 'Fin',
            value: session.endTime != null
                ? DateFormatter.formatTime(session.endTime!)
                : '—',
          ),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.battery_5_bar,
            label: 'Nivel',
            value: '${session.startLevel}% → ${session.endLevel ?? '—'}%',
          ),
          if (session.avgTemperature != null) ...[
            const SizedBox(height: 6),
            _Row(
              icon: Icons.thermostat_outlined,
              label: 'Temp. promedio',
              value: '${session.avgTemperature!.toStringAsFixed(1)}°C',
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodyMedium),
        Text(value, style: AppTextStyles.bodyLarge),
      ],
    );
  }
}
