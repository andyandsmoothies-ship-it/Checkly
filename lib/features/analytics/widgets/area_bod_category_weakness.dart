import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';

/// Category Performance & Weakness Analysis component.
class AreaBodCategoryWeakness extends StatelessWidget {
  final List<AreaCategoryWeakness> weaknesses;

  const AreaBodCategoryWeakness({
    super.key,
    required this.weaknesses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    // Sort weaknesses to put lowest scores on top
    final sortedWeaknesses = List<AreaCategoryWeakness>.from(weaknesses)
      ..sort((a, b) => a.avgScore.compareTo(b.avgScore));

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.cardinal,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Category Weakness Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'High-risk failure clusters sorted by the lowest average score.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextCol.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedWeaknesses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No weakness data found for the selected area.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subTextCol,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedWeaknesses.length,
              separatorBuilder: (context, index) => const Divider(
                height: 16,
                thickness: 1,
                color: AppColors.swan,
              ),
              itemBuilder: (context, index) {
                final item = sortedWeaknesses[index];
                final score = item.avgScore;
                final auditCount = item.auditCount;

                PillChip? statusChip;
                Color progressColor = AppColors.featherGreen;

                if (score < 70) {
                  statusChip = const PillChip(label: 'Critical Weakness', type: PillChipType.red);
                  progressColor = AppColors.cardinal;
                } else if (score < 85) {
                  statusChip = const PillChip(label: 'Needs Attention', type: PillChipType.yellow);
                  progressColor = AppColors.macaw;
                } else {
                  statusChip = const PillChip(label: 'Strong', type: PillChipType.green);
                  progressColor = AppColors.featherGreen;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.categoryName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: textCol,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (statusChip != null) ...[
                          const SizedBox(width: 8),
                          statusChip,
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 100.0,
                              minHeight: 8,
                              backgroundColor: isLight
                                  ? AppColors.polar
                                  : AppColors.eel,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${score.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: progressColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$auditCount audits submitted',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subTextCol,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.templateName.isNotEmpty)
                          Flexible(
                            child: Text(
                              'Template: ${item.templateName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subTextCol.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
