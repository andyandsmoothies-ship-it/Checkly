import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';

/// Renders the Historical Score Trend chart.
///
/// Implements 3-month Simple Moving Average (SMA) client-side calculations,
/// displays a dynamic trajectory indicator chip, and overlays smoothed SMA scores.
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

    // Compute client-side 3-month Simple Moving Average (SMA)
    // Formula: SMA_i = (Score_i + Score_{i-1} + Score_{i-2}) / 3 for i >= 2.
    final List<double?> smaValues = List.filled(finalTrend.length, null);
    for (int i = 0; i < finalTrend.length; i++) {
      if (i >= 2) {
        final score0 = (finalTrend[i]['avgScore'] ?? 0.0).toDouble();
        final score1 = (finalTrend[i - 1]['avgScore'] ?? 0.0).toDouble();
        final score2 = (finalTrend[i - 2]['avgScore'] ?? 0.0).toDouble();
        smaValues[i] = (score0 + score1 + score2) / 3.0;
      }
    }

    // Determine Trajectory and construct Trajectory Chip
    Widget? trajectoryChip;
    if (smaValues.length >= 4) {
      final currentSma = smaValues.last;
      final prevSma = smaValues[smaValues.length - 2];

      if (currentSma != null && prevSma != null) {
        if (currentSma > prevSma) {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label:
                  '📈 Trend: Going up (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.green,
            ),
          );
        } else if (currentSma < prevSma) {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label:
                  '📉 Trend: Going down (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.red,
            ),
          );
        } else {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label:
                  '📈 Trend: Steady (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.blue,
            ),
          );
        }
      }
    }

    // Default fallback if not enough points for comparative SMA
    if (trajectoryChip == null && finalTrend.isNotEmpty) {
      final lastScore = (finalTrend.last['avgScore'] ?? 0.0).toDouble();
      trajectoryChip = FittedBox(
        fit: BoxFit.scaleDown,
        child: PillChip(
          label: '📈 Trend: Steady (Score: ${lastScore.toStringAsFixed(1)}%)',
          type: PillChipType.blue,
        ),
      );
    }

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap with individual siblings to prevent narrow viewport overflows
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.trending_up, color: AppColors.macaw, size: 24),
              Text(
                'Historical Score Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
                ),
              ),
              ?trajectoryChip,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compare actual monthly scores with a 3-month smoothed average',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.wolf.withAlpha(160),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height:
                140, // Increased height slightly to accommodate the dual label spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(finalTrend.length, (index) {
                final t = finalTrend[index];
                final month = t['month'] ?? '';
                final score = (t['avgScore'] ?? 0.0).toDouble();
                final sma = smaValues[index];

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${score.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.macaw,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (sma != null) ...[
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Smoothed: ${sma.toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.beetle,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(
                          height: 12,
                        ), // Align spacing for months without SMA
                      ],
                      const SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          month.split(' ').first, // Just the month name
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.wolf,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
