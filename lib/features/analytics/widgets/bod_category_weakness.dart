import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodCategoryWeakness extends StatelessWidget {
  final List<dynamic> categoryBreakdown;

  const BodCategoryWeakness({super.key, required this.categoryBreakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback beautiful mock data if categoryBreakdown is empty
    final finalBreakdown = categoryBreakdown.isNotEmpty
        ? categoryBreakdown
        : [
            {
              'categoryName': 'Food Safety',
              'avgScore': 72.4,
              'failureCount': 18,
            },
            {
              'categoryName': 'Customer Service',
              'avgScore': 88.1,
              'failureCount': 2,
            },
            {
              'categoryName': 'Facility Cleanliness',
              'avgScore': 84.5,
              'failureCount': 6,
            },
          ];

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.iguana, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Category Compliance Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...finalBreakdown.map((c) {
            final name = c['categoryName'] ?? c['name'] ?? 'Unknown Category';
            final score = (c['avgScore'] ?? c['score'] ?? 0.0).toDouble();
            final failures = c['failureCount'] ?? c['failures'] ?? 0;

            final bool isWeak = score < 75.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.eel,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (failures > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isWeak
                                      ? AppColors.cardinal.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.canary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$failures Failures',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: isWeak
                                        ? AppColors.cardinal
                                        : AppColors.fox,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isWeak ? AppColors.cardinal : AppColors.eel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: AppColors.swan.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWeak ? AppColors.cardinal : AppColors.iguana,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
