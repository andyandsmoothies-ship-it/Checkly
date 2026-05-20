import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/analytics_data.dart';

/// Renders a store-vs-region radar polygon chart using fl_chart.
///
/// Shows:
///   - Store dataset: primary colour with 15% alpha fill
///   - Region dataset: grey dashed border with 10% alpha fill
///   - Legend row below the chart
///   - "No regional data yet" empty state when [radarData] is null
///
/// The [radarData.categories], [radarData.storeValues], and
/// [radarData.regionalValues] lists MUST be the same length. This is
/// guaranteed by [RadarData.fromJson] which intersects both maps and
/// orders by sorted category name.
class InsightsRadarChart extends StatelessWidget {
  final RadarData? radarData;

  const InsightsRadarChart({super.key, this.radarData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (radarData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.radar,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No regional data yet',
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

    final primary = theme.colorScheme.primary;
    final grey = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: radarData!.storeValues
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                      fillColor: primary.withValues(alpha: 0.15),
                      borderColor: primary,
                      borderWidth: 2,
                    ),
                    RadarDataSet(
                      dataEntries: radarData!.regionalValues
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                      fillColor: grey.withValues(alpha: 0.10),
                      borderColor: grey,
                      borderWidth: 1.5,
                    ),
                  ],
                  radarBorderData: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  tickCount: 5,
                  tickBorderData: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                    width: 1,
                  ),
                  ticksTextStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  titleTextStyle: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  getTitle: (index, _) {
                    if (index < 0 || index >= radarData!.categories.length) {
                      return const RadarChartTitle(text: '');
                    }
                    return RadarChartTitle(text: radarData!.categories[index]);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: primary),
                const SizedBox(width: 4),
                Text('Store', style: theme.textTheme.labelSmall),
                const SizedBox(width: 16),
                _LegendDot(color: grey),
                const SizedBox(width: 4),
                Text(
                  'Region',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.sageGray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
