import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../manager/bod_analytics_data.dart';

/// StrokeCard rendering SLA Overdue Action Plan segment counts.
class SlaOverdueActionPlansCard extends StatelessWidget {
  final List<SlaOverdueSegment>? slaOverdueBuckets;
  final Color? textColor;
  final Color? subtitleColor;

  const SlaOverdueActionPlansCard({
    super.key,
    required this.slaOverdueBuckets,
    this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    if (slaOverdueBuckets == null || slaOverdueBuckets!.isEmpty) {
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
                Icons.assignment_late_outlined,
                color: AppColors.cardinal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SLA Overdue Action Plans',
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
            children: slaOverdueBuckets!.map((segment) {
              Color countColor;
              if (segment.bucket.contains('31+')) {
                countColor = AppColors.cardinal;
              } else if (segment.bucket.contains('8-30')) {
                countColor = AppColors.fox;
              } else {
                countColor = AppColors.macaw;
              }
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.walkingFish.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${segment.count}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: countColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        segment.bucket,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: resolvedSubTextCol,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
