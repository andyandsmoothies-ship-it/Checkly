import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_manager.dart';

/// Modal bottom sheet displaying detailed historical audit metrics and bias rating for a selected auditor.
class BodAuditorDetailSheet extends StatefulWidget {
  final String auditorName;
  final BodAnalyticsManager manager;

  const BodAuditorDetailSheet({
    super.key,
    required this.auditorName,
    required this.manager,
  });

  @override
  State<BodAuditorDetailSheet> createState() => _BodAuditorDetailSheetState();
}

class _BodAuditorDetailSheetState extends State<BodAuditorDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Load auditor detail asynchronously when the sheet mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadAuditorDetail(widget.auditorName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          // Determine dynamic offline/cached Bias Rating
          String computedBias = 'Balanced';
          PillChipType biasChipType = PillChipType.blue;
          if (detail != null) {
            final avgScore = (detail['avgScore'] ?? detail['score'] ?? 0.0).toDouble();
            final nationalAvg = widget.manager.report?.chainKpis.avgScore ?? 85.0;

            if (avgScore <= nationalAvg - 5.0) {
              computedBias = 'Strict';
              biasChipType = PillChipType.red;
            } else if (avgScore >= nationalAvg + 5.0) {
              computedBias = 'Generous';
              biasChipType = PillChipType.green;
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.polar,
              borderRadius: BorderRadius.only(
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
                          color: AppColors.eel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.wolf),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                Text(
                  'Live data as of ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.wolf,
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No auditor productivity data available',
                        style: TextStyle(
                          color: AppColors.wolf,
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
                              color: AppColors.eel,
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
                                color: AppColors.walkingFish,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_ind,
                                color: AppColors.cardinal,
                              ),
                            ),
                            badges: [
                              PillChip(
                                label: '${(detail['avgScore'] ?? detail['score'] ?? 0.0).toDouble().toStringAsFixed(1)}%',
                                type: PillChipType.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          UniversalListCard(
                            title: 'Calibration Rating',
                            subtitle: 'Based on average deviation from corporate baseline',
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.iguana,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.humpback,
                              ),
                            ),
                            badges: [
                              PillChip(
                                label: computedBias,
                                type: biasChipType,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          UniversalListCard(
                            title: 'Activity Level',
                            subtitle: '${detail['completedCount'] ?? detail['completedAudits'] ?? detail['count'] ?? 0} total audits completed',
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.seaSponge,
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
        color: AppColors.polar,
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
            color: AppColors.polar,
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
