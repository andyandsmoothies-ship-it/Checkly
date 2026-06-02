import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/area_bod_manager.dart';
import 'regional_benchmarking_card.dart';
import 'sla_overdue_action_plans_card.dart';
import 'store_detail_skeleton.dart';
import 'category_performance_section.dart';
import 'recent_audits_section.dart';

/// Modal bottom sheet displaying detailed historical audit metrics and weaknesses for a selected store in the Area Manager view.
class AreaBodStoreDetailSheet extends StatefulWidget {
  final String storeId;
  final AreaBodManager manager;

  const AreaBodStoreDetailSheet({
    super.key,
    required this.storeId,
    required this.manager,
  });

  @override
  State<AreaBodStoreDetailSheet> createState() =>
      _AreaBodStoreDetailSheetState();
}

class _AreaBodStoreDetailSheetState extends State<AreaBodStoreDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadStoreDetail(widget.storeId);
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
          final isLoading = widget.manager.isStoreDetailLoading;
          final detail = widget.manager.storeDetail;
          final error = widget.manager.error;

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
                        detail?.storeName ?? 'Store Detail',
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
                  StoreDetailSkeleton(backgroundColor: bgCol),
                  const SizedBox(height: 8),
                  StoreDetailSkeleton(backgroundColor: bgCol),
                  const SizedBox(height: 8),
                  StoreDetailSkeleton(backgroundColor: bgCol),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No audit history available',
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
                          RegionalBenchmarkingCard(
                            quartileLabel: detail.quartileLabel,
                            regionalAvgScore: detail.regionalAvgScore,
                            recentAudits: detail.recentAudits,
                            textColor: textCol,
                            subtitleColor: subTextCol,
                          ),
                          if (detail.quartileLabel != null ||
                              detail.regionalAvgScore != null)
                            const SizedBox(height: 16),
                          SlaOverdueActionPlansCard(
                            slaOverdueBuckets: detail.slaOverdueBuckets,
                            textColor: textCol,
                            subtitleColor: subTextCol,
                          ),
                          if (detail.slaOverdueBuckets != null &&
                              detail.slaOverdueBuckets!.isNotEmpty)
                            const SizedBox(height: 16),
                           CategoryPerformanceSection(
                            categoryBreakdown: detail.categoryBreakdown,
                            textColor: textCol,
                            isLight: isLight,
                          ),
                          RecentAuditsSection(
                            recentAudits: detail.recentAudits,
                            textColor: textCol,
                            isLight: isLight,
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

