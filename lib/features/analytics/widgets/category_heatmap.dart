import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';

/// Data for a single category cell in the heatmap.
class CategoryScore {
  final String name;
  final double avgScore;
  final int auditCount;

  const CategoryScore({
    required this.name,
    required this.avgScore,
    required this.auditCount,
  });
}

/// 2×2 color-coded grid showing category scores.
/// Green ≥80, Yellow ≥60, Red <60.
class CategoryHeatmap extends StatelessWidget {
  final List<CategoryScore> categories;

  const CategoryHeatmap({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No category data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    // Pad to even number for 2-column grid
    final items = [...categories];
    if (items.length.isOdd) {
      items.add(const CategoryScore(name: '', avgScore: 0, auditCount: 0));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Scores',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Build 2-column rows
            for (int i = 0; i < items.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _HeatCell(score: items[i])),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          i + 1 < items.length && items[i + 1].name.isNotEmpty
                          ? _HeatCell(score: items[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final CategoryScore score;

  const _HeatCell({required this.score});

  Color _cellColor(ThemeData theme) {
    if (score.avgScore >= 80) return AppTheme.success;
    if (score.avgScore >= 60) return AppTheme.warning;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _cellColor(theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            score.name,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${score.avgScore.toStringAsFixed(0)}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            '${score.auditCount} audits',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
