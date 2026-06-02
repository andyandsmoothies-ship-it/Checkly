import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';

/// StrokeCard rendering regional average benchmark details and quartiles.
class RegionalBenchmarkingCard extends StatelessWidget {
  final String? quartileLabel;
  final double? regionalAvgScore;
  final List<RecentAuditEntry> recentAudits;
  final Color? textColor;
  final Color? subtitleColor;

  const RegionalBenchmarkingCard({
    super.key,
    required this.quartileLabel,
    required this.regionalAvgScore,
    required this.recentAudits,
    this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (quartileLabel == null && regionalAvgScore == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Resolve theme colors dynamically with safe fallbacks
    final resolvedTextCol = textColor ?? (isDark ? AppColors.snow : AppColors.eel);
    final resolvedSubTextCol = subtitleColor ?? (isDark ? AppColors.hare : AppColors.wolf);

    return StrokeCard(
      color: theme.colorScheme.surface,
      borderColor: AppColors.swan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.macaw,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Regional Benchmarking',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: resolvedTextCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (quartileLabel != null)
                PillChip(
                  label: quartileLabel!,
                  type: quartileLabel!.contains('Top 25%') ||
                          quartileLabel!.contains('Top 50%')
                      ? PillChipType.green
                      : PillChipType.yellow,
                ),
              if (regionalAvgScore != null)
                Text(
                  'Regional Avg: ${regionalAvgScore!.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: resolvedSubTextCol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (recentAudits.isNotEmpty && regionalAvgScore != null) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final storeAvg = recentAudits.map((e) => e.score).reduce((a, b) => a + b) /
                    recentAudits.length;
                final diff = storeAvg - regionalAvgScore!;
                final isAbove = diff >= 0;
                return Row(
                  children: [
                    Icon(
                      isAbove ? Icons.trending_up : Icons.trending_down,
                      color: isAbove ? AppColors.macaw : AppColors.cardinal,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAbove
                          ? '${diff.toStringAsFixed(1)}% above regional average'
                          : '${diff.abs().toStringAsFixed(1)}% below regional average',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isAbove ? AppColors.macaw : AppColors.cardinal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
