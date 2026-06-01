import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';

/// Auditor Productivity Scatter chart component.
class AreaBodAuditorScatter extends StatelessWidget {
  final List<AreaAuditorProductivity> auditors;

  const AreaBodAuditorScatter({
    super.key,
    required this.auditors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    // Filter out entries with invalid stats
    final validAuditors = auditors.where((a) => a.completedCount > 0).toList();

    // Sort to list high performers first
    validAuditors.sort((a, b) => b.completedCount.compareTo(a.completedCount));

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: AppColors.macaw,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auditor Productivity Scatter',
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
            'Compares auditor throughput (number of completed audits) vs. quality (average score).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextCol.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (validAuditors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No auditor performance data found.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subTextCol,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else ...[
            // Simple visual scatter grid
            _buildVisualScatterGrid(context, validAuditors),
            const SizedBox(height: 20),
            // High density details list
            Text(
              'Auditor Standings',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: textCol,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: validAuditors.length,
              separatorBuilder: (context, index) => const Divider(
                height: 12,
                thickness: 1,
                color: AppColors.swan,
              ),
              itemBuilder: (context, index) {
                final auditor = validAuditors[index];
                final score = auditor.avgScore;
                final count = auditor.completedCount;

                final PillChip productivityChip;
                if (count >= 10) {
                  productivityChip = const PillChip(label: 'High Output', type: PillChipType.green);
                } else if (count >= 5) {
                  productivityChip = const PillChip(label: 'Medium Output', type: PillChipType.blue);
                } else {
                  productivityChip = const PillChip(label: 'Low Output', type: PillChipType.yellow);
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isLight ? AppColors.polar : AppColors.eel,
                      child: Text(
                        auditor.auditorName.isNotEmpty
                            ? auditor.auditorName.trim().characters.first.toUpperCase()
                            : 'A',
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
                            children: [
                              Flexible(
                                child: Text(
                                  auditor.auditorName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: textCol,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              productivityChip,
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count completed audits',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subTextCol,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: score >= 85
                            ? AppColors.featherGreen
                            : (score >= 70 ? AppColors.macaw : AppColors.cardinal),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualScatterGrid(BuildContext context, List<AreaAuditorProductivity> list) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final gridLineColor = isLight ? AppColors.swan : AppColors.swan.withValues(alpha: 0.2);

    // Find limits for mapping coordinates
    double maxScore = 100.0;
    double minScore = 50.0; // Assume minimum visual floor is 50%
    int maxCount = 1;

    for (var a in list) {
      if (a.completedCount > maxCount) maxCount = a.completedCount;
    }
    // Pad max count so elements aren't right at the top boundary
    maxCount = maxCount + 2;

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isLight ? AppColors.polar : AppColors.eel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gridLineColor, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          // Background reference grid lines
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: index == 3 ? Colors.transparent : gridLineColor.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Scatter points mapping
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: list.map((auditor) {
                  // Map average score to X coordinate (minScore to maxScore -> 0 to width)
                  final double scorePercent =
                      ((auditor.avgScore - minScore) / (maxScore - minScore)).clamp(0.0, 1.0);
                  // Map completed count to Y coordinate (0 to maxCount -> height to 0)
                  final double countPercent =
                      (auditor.completedCount / maxCount).clamp(0.0, 1.0);

                  final double xPos = scorePercent * (constraints.maxWidth - 24);
                  final double yPos = (1.0 - countPercent) * (constraints.maxHeight - 24);

                  return Positioned(
                    left: xPos,
                    top: yPos,
                    child: Tooltip(
                      message: '${auditor.auditorName}\nScore: ${auditor.avgScore.toStringAsFixed(1)}%\nAudits: ${auditor.completedCount}',
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.macaw.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.snow, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${auditor.completedCount}',
                            style: const TextStyle(
                              color: AppColors.snow,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          // Quadrant label tags
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'High Volume ⬆',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.wolf.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Text(
              'High Quality ➡',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.wolf.withValues(alpha: 0.5),
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
