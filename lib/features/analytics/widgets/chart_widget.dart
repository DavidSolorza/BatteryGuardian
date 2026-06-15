import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({
    super.key,
    required this.title,
    required this.data,
    required this.labels,
    this.barColor,
  });

  final String title;
  final List<double> data;
  final List<String> labels;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;
    final chartColor = barColor ?? colors.primary;

    final maxValue = data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b);
    final hasData = maxValue > 0;
    final maxY = hasData ? (maxValue * 1.2).clamp(10.0, double.infinity) : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(title, style: textStyles.titleLarge),
          const SizedBox(height: 24),
          if (!hasData)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Sin datos en este periodo',
                  style: textStyles.bodyMedium,
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}m',
                        style: textStyles.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: textStyles.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[index],
                        color: chartColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            ),
        ],
      ),
    );
  }
}
