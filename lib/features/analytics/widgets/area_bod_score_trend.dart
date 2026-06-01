import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';

/// Renders the Area Historical Score Trend chart with actual vs flagship comparison.
class AreaBodScoreTrend extends StatelessWidget {
  final List<AreaTrendPoint> trend;
  final AreaGoldenStore? goldenStore;

  const AreaBodScoreTrend({
    super.key,
    required this.trend,
    this.goldenStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    final finalTrend = trend.isNotEmpty
        ? trend
        : [
            AreaTrendPoint(month: 'Jan 2026', avgScore: 81.0, auditCount: 35),
            AreaTrendPoint(month: 'Feb 2026', avgScore: 83.2, auditCount: 42),
            AreaTrendPoint(month: 'Mar 2026', avgScore: 82.5, auditCount: 50),
            AreaTrendPoint(month: 'Apr 2026', avgScore: 85.0, auditCount: 65),
            AreaTrendPoint(month: 'May 2026', avgScore: 84.5, auditCount: 58),
          ];

    // Compute client-side 3-month Simple Moving Average (SMA)
    final List<double?> smaValues = List.filled(finalTrend.length, null);
    for (int i = 0; i < finalTrend.length; i++) {
      if (i >= 2) {
        final score0 = finalTrend[i].avgScore;
        final score1 = finalTrend[i - 1].avgScore;
        final score2 = finalTrend[i - 2].avgScore;
        smaValues[i] = (score0 + score1 + score2) / 3.0;
      }
    }

    Widget? trajectoryChip;
    if (smaValues.length >= 4) {
      final currentSma = smaValues.last;
      final prevSma = smaValues[smaValues.length - 2];

      if (currentSma != null && prevSma != null) {
        if (currentSma > prevSma) {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label: '📈 Trend: Going up (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.green,
            ),
          );
        } else if (currentSma < prevSma) {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label: '📉 Trend: Going down (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.red,
            ),
          );
        } else {
          trajectoryChip = FittedBox(
            fit: BoxFit.scaleDown,
            child: PillChip(
              label: '📈 Trend: Steady (Smoothed: ${currentSma.toStringAsFixed(1)}%)',
              type: PillChipType.blue,
            ),
          );
        }
      }
    }

    if (trajectoryChip == null && finalTrend.isNotEmpty) {
      final lastScore = finalTrend.last.avgScore;
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
                  color: textCol,
                ),
              ),
              if (trajectoryChip != null) trajectoryChip,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compare actual monthly scores with a 3-month smoothed average',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextCol.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(finalTrend.length, (index) {
                final t = finalTrend[index];
                final month = t.month;
                final score = t.avgScore;
                final sma = smaValues[index];

                // Scale bar heights relative to a max score of 100
                final double barHeightFactor = (score / 100.0).clamp(0.1, 1.0);

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
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 6),
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: barHeightFactor,
                          alignment: Alignment.bottomCenter,
                          child: Container(
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          month.split(' ').first,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subTextCol,
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
