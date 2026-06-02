import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';

/// Reusable widget for displaying the Category Performance breakdown list inside boardroom store detail sheets.
class CategoryPerformanceSection extends StatelessWidget {
  final List<CategoryScoreEntry> categoryBreakdown;
  final Color textColor;
  final bool isLight;

  const CategoryPerformanceSection({
    super.key,
    required this.categoryBreakdown,
    required this.textColor,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Category Performance',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ...categoryBreakdown.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: UniversalListCard(
              title: cat.categoryName,
              subtitle: 'Average Section Score',
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLight
                      ? AppColors.walkingFish
                      : AppColors.walkingFish.withValues(
                          alpha: 0.2,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category,
                  color: AppColors.cardinal,
                ),
              ),
              badges: [
                PillChip(
                  label: '${cat.avgScore.toStringAsFixed(1)}%',
                  type: PillChipType.blue,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
