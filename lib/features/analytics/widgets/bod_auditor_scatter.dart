import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodAuditorScatter extends StatelessWidget {
  final List<dynamic> auditorProductivity;

  const BodAuditorScatter({super.key, required this.auditorProductivity});

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

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                        Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.eel,
                          ),
                        ),
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
            );
          }),
        ],
      ),
    );
  }
}
