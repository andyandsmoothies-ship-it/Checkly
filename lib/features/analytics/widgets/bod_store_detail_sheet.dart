import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/bod_analytics_manager.dart';
import 'regional_benchmarking_card.dart';
import 'sla_overdue_action_plans_card.dart';
import 'store_detail_skeleton.dart';
import 'category_performance_section.dart';
import 'recent_audits_section.dart';

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
                  const StoreDetailSkeleton(),
                  const SizedBox(height: 8),
                  const StoreDetailSkeleton(),
                  const SizedBox(height: 8),
                  const StoreDetailSkeleton(),
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
                          RegionalBenchmarkingCard(
                            quartileLabel: detail.quartileLabel,
                            regionalAvgScore: detail.regionalAvgScore,
                            recentAudits: detail.recentAudits,
                          ),
                          if (detail.quartileLabel != null ||
                              detail.regionalAvgScore != null)
                            const SizedBox(height: 16),
                          SlaOverdueActionPlansCard(
                            slaOverdueBuckets: detail.slaOverdueBuckets,
                          ),
                          if (detail.slaOverdueBuckets != null &&
                              detail.slaOverdueBuckets!.isNotEmpty)
                            const SizedBox(height: 16),
                           CategoryPerformanceSection(
                            categoryBreakdown: detail.categoryBreakdown,
                            textColor: AppColors.eel,
                            isLight: true,
                          ),
                          RecentAuditsSection(
                            recentAudits: detail.recentAudits,
                            textColor: AppColors.eel,
                            isLight: true,
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

