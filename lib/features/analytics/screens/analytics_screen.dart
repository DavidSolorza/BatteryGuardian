import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/battery_status_helper.dart';
import '../../../core/utils/charge_metrics.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/battery_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/chart_widget.dart';
import '../widgets/level_trend_chart.dart';
import '../widgets/live_charge_card.dart';
import '../widgets/recent_sessions_card.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAnalytics();
    });
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final battery = context.read<BatteryProvider>();
      if (BatteryStatusHelper.isPluggedIn(battery.batteryInfo.state) ||
          battery.chargingStartedAt != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AnalyticsProvider, BatteryProvider, SettingsProvider>(
      builder: (context, analytics, battery, settings, _) {
        final colors = context.appColors;
        final textStyles = context.textStyles;

        final liveStats = ChargeMetrics.fromSession(
          info: battery.batteryInfo,
          startedAt: battery.chargingStartedAt,
          startLevel: battery.activeSession?.startLevel,
          targetLevel: settings.alertLevel,
        );

        if (analytics.isLoading && analytics.data.completedSessionCount == 0) {
          return ResponsiveContent(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                LiveChargeCard(stats: liveStats),
                const SizedBox(height: 12),
                const SkeletonLoader(height: 120, borderRadius: 20),
              ],
            ),
          );
        }

        if (analytics.error != null) {
          return ErrorState(
            message: analytics.error!,
            onRetry: analytics.refresh,
          );
        }

        final data = analytics.data;
        final hasHistory = data.completedSessionCount > 0;
        final columns = Responsive.gridColumns(
          context,
          compact: 2,
          medium: 2,
          expanded: 4,
        );

        return RefreshIndicator(
          onRefresh: analytics.refresh,
          color: colors.primary,
          backgroundColor: colors.card,
          child: ResponsiveContent(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                LiveChargeCard(stats: liveStats),
                const SizedBox(height: 20),
                if (!hasHistory && !liveStats.isActive)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aún no hay historial',
                          style: textStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Conecta el cargador y espera unos segundos. '
                          'Al desconectar, la sesión quedará guardada.',
                          style: textStyles.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else if (hasHistory) ...[
                  Text(
                    'Resumen · ${data.completedSessionCount} cargas',
                    style: textStyles.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: Responsive.isCompact(context) ? 1.4 : 1.5,
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
                        color: AppColors.info,
                      ),
                      StatCard(
                        icon: Icons.insights,
                        label: 'Cuidado batería',
                        value: '${data.careScore}/100',
                        color: data.careScore >= 70
                            ? colors.primary
                            : colors.warning,
                      ),
                      StatCard(
                        icon: Icons.battery_full,
                        label: 'Cargas al 100%',
                        value: '${data.fullChargeCount}',
                        color: data.fullChargeCount > 2
                            ? colors.warning
                            : colors.primary,
                      ),
                      StatCard(
                        icon: Icons.thermostat,
                        label: 'Temp. promedio',
                        value: data.avgTemperature > 0
                            ? '${data.avgTemperature.toStringAsFixed(1)}°C'
                            : 'N/D',
                        color: colors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    icon: Icons.power,
                    label: 'Horas conectado (total)',
                    value: '${data.totalConnectedHours.toStringAsFixed(1)} h',
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 20),
                  if (data.levelHistory.length >= 2)
                    LevelTrendChart(levels: data.levelHistory),
                  if (data.levelHistory.length >= 2)
                    const SizedBox(height: 16),
                  if (Responsive.isExpanded(context))
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ChartWidget(
                            title: 'Carga semanal (min)',
                            data: data.weeklyDurations,
                            labels: data.weeklyLabels,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ChartWidget(
                            title: 'Carga mensual (min)',
                            data: data.monthlyDurations,
                            labels: data.monthlyLabels,
                            barColor: AppColors.info,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ChartWidget(
                      title: 'Carga semanal (min)',
                      data: data.weeklyDurations,
                      labels: data.weeklyLabels,
                    ),
                    const SizedBox(height: 16),
                    ChartWidget(
                      title: 'Carga mensual (min)',
                      data: data.monthlyDurations,
                      labels: data.monthlyLabels,
                      barColor: AppColors.info,
                    ),
                  ],
                  const SizedBox(height: 20),
                  RecentSessionsCard(sessions: data.recentSessions),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
