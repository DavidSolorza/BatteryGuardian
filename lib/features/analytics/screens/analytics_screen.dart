import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../providers/analytics_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/chart_widget.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, _) {
        if (analytics.isLoading) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              SkeletonLoader(height: 120, borderRadius: 20),
              SizedBox(height: 12),
              SkeletonLoader(height: 120, borderRadius: 20),
              SizedBox(height: 20),
              SkeletonLoader(height: 260, borderRadius: 20),
            ],
          );
        }

        if (analytics.error != null) {
          return ErrorState(
            message: analytics.error!,
            onRetry: analytics.refresh,
          );
        }

        final data = analytics.data;
        final hasData = data.weeklyDurations.any((d) => d > 0);

        if (!hasData) {
          return EmptyState(
            icon: Icons.analytics_outlined,
            title: 'Sin datos analíticos',
            message:
                'Las estadísticas se generarán después de registrar cargas.',
            action: FilledButton.icon(
              onPressed: analytics.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: analytics.refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo promedio',
                    value: DurationFormatter.format(data.avgChargeDuration),
                  ),
                  StatCard(
                    icon: Icons.repeat,
                    label: 'Cargas hoy',
                    value: '${data.dailyChargeCount}',
                    color: const Color(0xFF38BDF8),
                  ),
                  StatCard(
                    icon: Icons.battery_full,
                    label: 'Cargas al 100%',
                    value: '${data.fullChargeCount}',
                    color: AppColors.warning,
                  ),
                  StatCard(
                    icon: Icons.thermostat,
                    label: 'Temp. promedio',
                    value: data.avgTemperature > 0
                        ? '${data.avgTemperature.toStringAsFixed(1)}°C'
                        : 'N/D',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                icon: Icons.power,
                label: 'Horas conectado (total)',
                value: '${data.totalConnectedHours.toStringAsFixed(1)} h',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 20),
              ChartWidget(
                title: 'Carga semanal (minutos)',
                data: data.weeklyDurations,
                labels: data.weeklyLabels,
              ),
              const SizedBox(height: 16),
              ChartWidget(
                title: 'Carga mensual (minutos)',
                data: data.monthlyDurations,
                labels: data.monthlyLabels,
                barColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
        );
      },
    );
  }
}
