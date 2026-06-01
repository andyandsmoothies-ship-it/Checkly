import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_manager.dart';

/// Modal bottom sheet displaying detailed historical audit metrics for a selected auditor in the Area Manager view.
class AreaBodAuditorDetailSheet extends StatefulWidget {
  final String auditorName;
  final AreaBodManager manager;

  const AreaBodAuditorDetailSheet({
    super.key,
    required this.auditorName,
    required this.manager,
  });

  @override
  State<AreaBodAuditorDetailSheet> createState() =>
      _AreaBodAuditorDetailSheetState();
}

class _AreaBodAuditorDetailSheetState extends State<AreaBodAuditorDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadAuditorDetail(widget.auditorName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgCol = isLight ? AppColors.polar : AppColors.eel;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: AnimatedBuilder(
        animation: widget.manager,
        builder: (context, _) {
          final isLoading = widget.manager.isAuditorDetailLoading;
          final detail = widget.manager.auditorDetail;
          final error = widget.manager.error;

          String computedBias = 'Balanced';
          PillChipType biasChipType = PillChipType.blue;
          if (detail != null) {
            final avgScore = detail.avgScore;
            final baselineAvg = widget.manager.report?.kpis.avgScore ?? 85.0;

            if (avgScore <= baselineAvg - 5.0) {
              computedBias = 'Strict';
              biasChipType = PillChipType.red;
            } else if (avgScore >= baselineAvg + 5.0) {
              computedBias = 'Generous';
              biasChipType = PillChipType.green;
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.auditorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subTextCol),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                Text(
                  'Live data as of ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading) ...[
                  const _SkeletonItem(),
                  const SizedBox(height: 8),
                  const _SkeletonItem(),
                ] else if (error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: AppColors.cardinal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else if (detail == null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No auditor productivity data available',
                        style: TextStyle(
                          color: subTextCol,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Performance Analysis',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: 8),
                          UniversalListCard(
                            title: 'Auditor Stats',
                            subtitle: 'Average Audit Score',
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
                                Icons.assignment_ind,
                                color: AppColors.cardinal,
                              ),
                            ),
                            badges: [
                              PillChip(
                                label: '${detail.avgScore.toStringAsFixed(1)}%',
                                type: PillChipType.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          UniversalListCard(
                            title: 'Calibration Rating',
                            subtitle:
                                'Based on average deviation from area baseline',
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isLight
                                    ? AppColors.iguana
                                    : AppColors.iguana.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.humpback,
                              ),
                            ),
                            badges: [
                              PillChip(label: computedBias, type: biasChipType),
                            ],
                          ),
                          const SizedBox(height: 12),
                          UniversalListCard(
                            title: 'Activity Level',
                            subtitle:
                                '${detail.completedCount} total audits completed',
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isLight
                                    ? AppColors.seaSponge
                                    : AppColors.seaSponge.withValues(
                                        alpha: 0.2,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonItem extends StatefulWidget {
  const _SkeletonItem();

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      return StrokeCard(
        color: Theme.of(context).brightness == Brightness.light
            ? AppColors.polar
            : AppColors.eel,
        borderColor: AppColors.swan,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.swan,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 150, color: AppColors.swan),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: AppColors.swan),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.5),
          child: StrokeCard(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.polar
                : AppColors.eel,
            borderColor: AppColors.swan,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.swan,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 150, color: AppColors.swan),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: AppColors.swan),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
