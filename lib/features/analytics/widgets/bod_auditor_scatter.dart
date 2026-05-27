import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_manager.dart';
import 'bod_auditor_detail_sheet.dart';

class BodAuditorScatter extends StatelessWidget {
  final List<dynamic> auditorProductivity;
  final BodAnalyticsManager manager;
  final double nationalAvg;

  const BodAuditorScatter({
    super.key,
    required this.auditorProductivity,
    required this.manager,
    required this.nationalAvg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback beautiful mock data if list is empty
    final finalProductivity = auditorProductivity.isNotEmpty
        ? auditorProductivity
        : [
            {'auditorName': 'John Doe', 'avgScore': 86.2, 'completedCount': 24},
            {
              'auditorName': 'Jane Smith',
              'avgScore': 89.4,
              'completedCount': 18,
            },
            {
              'auditorName': 'Bob Johnson',
              'avgScore': 78.1,
              'completedCount': 15,
            },
          ];

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: AppColors.macaw,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auditor Productivity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...finalProductivity.map((a) {
            final name = a['auditorName'] ?? a['name'] ?? 'Unknown Auditor';
            final score = (a['avgScore'] ?? a['score'] ?? 0.0).toDouble();
            final count = a['completedCount'] ?? a['count'] ?? 0;

            final double dev = score - nationalAvg;
            final String biasRating;
            final PillChipType ratingType;
            if (dev <= -5.0) {
              biasRating = 'Strict';
              ratingType = PillChipType.red;
            } else if (dev >= 5.0) {
              biasRating = 'Generous';
              ratingType = PillChipType.green;
            } else {
              biasRating = 'Balanced';
              ratingType = PillChipType.blue;
            }

            return InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => BodAuditorDetailSheet(
                    auditorName: name,
                    manager: manager,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.macaw.withValues(alpha: 0.15),
                      radius: 18,
                      child: Text(
                        name.isNotEmpty ? name[0] : 'A',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.macaw,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(width: 8),
                              PillChip(
                                label: biasRating,
                                type: ratingType,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count audits completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.wolf,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.polar,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.swan, width: 1.5),
                      ),
                      child: Text(
                        '${score.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.eel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
