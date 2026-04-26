import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';

/// Data point for the trend chart.
class TrendPoint {
  final String month;
  final double avgScore;
  final int count;

  const TrendPoint(this.month, this.avgScore, this.count);
}

/// Line chart displaying monthly average scores using fl_chart.
///
/// Shows:
/// - Blue line for actual score trend
/// - Dashed grey line for 80% target threshold
/// - "No data yet" placeholder when [data] is empty (AC2)
class TrendChart extends StatelessWidget {
  final List<TrendPoint> data;
  final void Function(String month)? onMonthTap;

  const TrendChart({super.key, required this.data, this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // AC2: Empty state — show placeholder, not crash
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No data yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // AC1: fl_chart LineChart replaces LinearProgressIndicator bars
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.avgScore);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  strokeWidth: 1,
                ),
              ),
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
                    interval: 20,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      // Show abbreviated month label
                      final label = data[idx].month;
                      final short = label.length > 5
                          ? label.substring(5)
                          : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(short, style: theme.textTheme.labelSmall),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Actual score line
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                // Target threshold line (80%)
                LineChartBarData(
                  spots: List.generate(
                    data.length,
                    (i) => FlSpot(i.toDouble(), 80),
                  ),
                  isCurved: false,
                  color: AppTheme.warning,
                  barWidth: 1,
                  dashArray: [8, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  if (onMonthTap == null) return;
                  final spots = response?.lineBarSpots;
                  if (spots == null || spots.isEmpty) return;
                  // First spot from the score line (barIndex 0)
                  final spot = spots.firstWhere(
                    (s) => s.barIndex == 0,
                    orElse: () => spots.first,
                  );
                  final idx = spot.x.toInt();
                  if (idx >= 0 && idx < data.length && data[idx].count > 0) {
                    onMonthTap!(data[idx].month);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      if (spot.barIndex == 1) return null; // Skip target line
                      final idx = spot.x.toInt();
                      final point = idx >= 0 && idx < data.length
                          ? data[idx]
                          : null;
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}'
                        '${point != null ? '\n${point.count} audits' : ''}',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
