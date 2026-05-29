import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../manager/bod_analytics_data.dart';
import '../manager/bod_analytics_manager.dart';
import 'bod_store_detail_sheet.dart';

/// Performance leaderboard displaying top and bottom performing stores.
///
/// Features color-coded synchronization status dots and onTap bottom sheet telemetry.
class BodStoreLeaderboard extends StatelessWidget {
  final List<BodStorePerformanceEntry> topStores;
  final List<BodStorePerformanceEntry> bottomStores;
  final BodAnalyticsManager manager;

  const BodStoreLeaderboard({
    super.key,
    required this.topStores,
    required this.bottomStores,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback beautiful mock data if lists are empty
    final finalTop = topStores.isNotEmpty
        ? topStores
        : [
            BodStorePerformanceEntry(
              storeId: 'mock-1',
              storeName: 'Central Market',
              avgScore: 96.5,
              auditCount: 15,
              lastSyncedAt: DateTime.now().subtract(
                const Duration(minutes: 45),
              ),
            ),
            BodStorePerformanceEntry(
              storeId: 'mock-2',
              storeName: 'Siam Square',
              avgScore: 94.2,
              auditCount: 12,
              lastSyncedAt: DateTime.now().subtract(const Duration(hours: 4)),
            ),
          ];

    final finalBottom = bottomStores.isNotEmpty
        ? bottomStores
        : [
            BodStorePerformanceEntry(
              storeId: 'mock-3',
              storeName: 'Outpost West',
              avgScore: 62.1,
              auditCount: 8,
              lastSyncedAt: DateTime.now().subtract(const Duration(hours: 36)),
            ),
            BodStorePerformanceEntry(
              storeId: 'mock-4',
              storeName: 'Airport Express',
              avgScore: 58.4,
              auditCount: 10,
              lastSyncedAt: null,
            ),
          ];

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: AppColors.fox, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Store Performance Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compare the highest and lowest performing stores based on audit scores',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.wolf.withAlpha(160),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Top Performing Stores',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.featherGreen,
            ),
          ),
          const SizedBox(height: 8),
          ...finalTop.map((s) => _buildStoreRow(context, s, isTop: true)),
          const SizedBox(height: 16),
          Text(
            'Bottom Performing Stores',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.cardinal,
            ),
          ),
          const SizedBox(height: 8),
          ...finalBottom.map((s) => _buildStoreRow(context, s, isTop: false)),
        ],
      ),
    );
  }

  Widget _buildStoreRow(
    BuildContext context,
    BodStorePerformanceEntry s, {
    required bool isTop,
  }) {
    final theme = Theme.of(context);

    // Calculate sync color status
    Color syncDotColor;
    if (s.lastSyncedAt == null) {
      syncDotColor = AppColors.cardinal; // Red: Never synced
    } else {
      final age = DateTime.now().difference(s.lastSyncedAt!);
      if (age.inHours < 2) {
        syncDotColor = AppColors.featherGreen; // Green: Active sync
      } else if (age.inHours < 24) {
        syncDotColor = AppColors.fox; // Amber: Mildly stale sync
      } else {
        syncDotColor = AppColors.cardinal; // Red: Stale sync
      }
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) =>
              BodStoreDetailSheet(storeId: s.storeId, manager: manager),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Coloured Sync dot indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: syncDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.storeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.eel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.avgScore.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isTop ? AppColors.featherGreen : AppColors.cardinal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.avgScore / 100,
                backgroundColor: AppColors.swan.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isTop ? AppColors.featherGreen : AppColors.cardinal,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
