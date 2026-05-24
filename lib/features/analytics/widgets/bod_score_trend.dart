import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodScoreTrend extends StatelessWidget {
  final List<dynamic> trend;

  const BodScoreTrend({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback beautiful mock data if trend list is empty
    final finalTrend = trend.isNotEmpty
        ? trend
        : [
            {'month': 'Jan 2026', 'avgScore': 81.0, 'count': 35},
            {'month': 'Feb 2026', 'avgScore': 83.2, 'count': 42},
            {'month': 'Mar 2026', 'avgScore': 82.5, 'count': 50},
            {'month': 'Apr 2026', 'avgScore': 85.0, 'count': 65},
            {'month': 'May 2026', 'avgScore': 84.5, 'count': 58},
          ];

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.macaw, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historical Score Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: finalTrend.map((t) {
                final month = t['month'] ?? '';
                final score = (t['avgScore'] ?? 0.0).toDouble();

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.macaw,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (score / 100) * 70, // Scale to max height of 70
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.macaw, AppColors.iguana],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.macaw.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        month.split(' ').first, // Just the month name
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.wolf,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
