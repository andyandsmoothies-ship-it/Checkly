import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_manager.dart';

/// Modal bottom sheet displaying detailed historical audit metrics and weaknesses for a selected store.
class BodStoreDetailSheet extends StatefulWidget {
  final String storeId;
  final BodAnalyticsManager manager;

  const BodStoreDetailSheet({
    super.key,
    required this.storeId,
    required this.manager,
  });

  @override
  State<BodStoreDetailSheet> createState() => _BodStoreDetailSheetState();
}

class _BodStoreDetailSheetState extends State<BodStoreDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Load store detail asynchronously when the sheet mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadStoreDetail(widget.storeId);
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
          final isLoading = widget.manager.isStoreDetailLoading;
          final detail = widget.manager.storeDetail;
          final error = widget.manager.error;

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
                        detail?.storeName ?? 'Store Detail',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.eel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.wolf),
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
                ] else if (detail == null || detail.recentAudits.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No audit history available',
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
                          if (detail.quartileLabel != null ||
                              detail.regionalAvgScore != null) ...[
                            StrokeCard(
                              color: theme.colorScheme.surface,
                              borderColor: AppColors.swan,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.analytics_outlined,
                                        color: AppColors.macaw,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Regional Benchmarking',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.eel,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (detail.quartileLabel != null)
                                        PillChip(
                                          label: detail.quartileLabel!,
                                          type:
                                              detail.quartileLabel!.contains(
                                                    'Top 25%',
                                                  ) ||
                                                  detail.quartileLabel!
                                                      .contains('Top 50%')
                                              ? PillChipType.green
                                              : PillChipType.yellow,
                                        ),
                                      if (detail.regionalAvgScore != null)
                                        Text(
                                          'Regional Avg: ${detail.regionalAvgScore!.toStringAsFixed(1)}%',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppColors.wolf,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                    ],
                                  ),
                                  if (detail.recentAudits.isNotEmpty &&
                                      detail.regionalAvgScore != null) ...[
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final storeAvg =
                                            detail.recentAudits
                                                .map((e) => e.score)
                                                .reduce((a, b) => a + b) /
                                            detail.recentAudits.length;
                                        final diff =
                                            storeAvg - detail.regionalAvgScore!;
                                        final isAbove = diff >= 0;
                                        return Row(
                                          children: [
                                            Icon(
                                              isAbove
                                                  ? Icons.trending_up
                                                  : Icons.trending_down,
                                              color: isAbove
                                                  ? AppColors.macaw
                                                  : AppColors.cardinal,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isAbove
                                                  ? '${diff.toStringAsFixed(1)}% above regional average'
                                                  : '${diff.abs().toStringAsFixed(1)}% below regional average',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isAbove
                                                        ? AppColors.macaw
                                                        : AppColors.cardinal,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (detail.slaOverdueBuckets != null &&
                              detail.slaOverdueBuckets!.isNotEmpty) ...[
                            StrokeCard(
                              color: theme.colorScheme.surface,
                              borderColor: AppColors.swan,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_late_outlined,
                                        color: AppColors.cardinal,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'SLA Overdue Action Plans',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.eel,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: detail.slaOverdueBuckets!.map((
                                      segment,
                                    ) {
                                      Color countColor;
                                      if (segment.bucket.contains('31+')) {
                                        countColor = AppColors.cardinal;
                                      } else if (segment.bucket.contains(
                                        '8-30',
                                      )) {
                                        countColor = AppColors.fox;
                                      } else {
                                        countColor = AppColors.macaw;
                                      }
                                      return Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.walkingFish
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${segment.count}',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: countColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                segment.bucket,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.wolf,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (detail.categoryBreakdown.isNotEmpty) ...[
                            Text(
                              'Category Performance',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.eel,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...detail.categoryBreakdown.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: UniversalListCard(
                                  title: cat.categoryName,
                                  subtitle: 'Average Section Score',
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.walkingFish,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.category,
                                      color: AppColors.cardinal,
                                    ),
                                  ),
                                  badges: [
                                    PillChip(
                                      label:
                                          '${cat.avgScore.toStringAsFixed(1)}%',
                                      type: PillChipType.blue,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Recent Audits',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.eel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...detail.recentAudits.map((audit) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: UniversalListCard(
                                title: 'Audit by ${audit.auditorName}',
                                subtitle:
                                    'Date: ${audit.date.length >= 10 ? audit.date.substring(0, 10) : audit.date}',
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.walkingFish,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment,
                                    color: AppColors.cardinal,
                                  ),
                                ),
                                badges: [
                                  PillChip(
                                    label: '${audit.score.toStringAsFixed(1)}%',
                                    type: PillChipType.blue,
                                  ),
                                ],
                              ),
                            );
                          }),
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
