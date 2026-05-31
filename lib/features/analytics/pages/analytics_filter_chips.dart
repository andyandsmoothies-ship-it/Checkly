import 'package:flutter/material.dart';

import '../../../_shared/widgets/warm_chip.dart';
import '../manager/analytics_manager.dart';

/// Horizontal scrollable chip bar that shows active filter chips (dismissible)
/// and date-range selection chips. Rendered at the top of [AnalyticsPage].
class AnalyticsFilterChips extends StatelessWidget {
  final AnalyticsManager manager;
  final int activeFilterCount;
  final VoidCallback onShowFilterSheet;
  final VoidCallback onPickCustomDateRange;

  const AnalyticsFilterChips({
    super.key,
    required this.manager,
    required this.activeFilterCount,
    required this.onShowFilterSheet,
    required this.onPickCustomDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // ── Active filter chips (dismissible) ──
          if (manager.selectedProvince != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text('Province: ${manager.selectedProvince}'),
                onDeleted: () {
                  manager.selectedProvince = null;
                  manager.selectedStore = null;
                  manager.load();
                },
              ),
            ),
          if (manager.selectedStore != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(manager.selectedStore!),
                onDeleted: () {
                  manager.selectedStore = null;
                  manager.load();
                },
              ),
            ),
          if (manager.selectedType != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(manager.selectedType!),
                onDeleted: () {
                  manager.selectedType = null;
                  manager.load();
                },
              ),
            ),

          if (manager.selectedAuditor != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(manager.selectedAuditor!),
                onDeleted: () {
                  manager.selectedAuditor = null;
                  manager.load();
                },
              ),
            ),
          if (manager.selectedStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(
                  manager.selectedStatus == 'completed'
                      ? 'Completed'
                      : 'In Progress',
                ),
                onDeleted: () {
                  manager.selectedStatus = null;
                  manager.load();
                },
              ),
            ),
          if (manager.selectedReviewStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                label: Text(
                  manager.selectedReviewStatus == 'pending'
                      ? 'Pending Review'
                      : 'Approved',
                ),
                onDeleted: () {
                  manager.selectedReviewStatus = null;
                  manager.load();
                },
              ),
            ),

          // ── Date range chips ──
          WarmChip(
            label: 'All Time',
            selected: manager.dateRange == 'all',
            onTap: () => manager.setDateRange('all'),
          ),
          const SizedBox(width: 8),
          WarmChip(
            label: '30d',
            selected: manager.dateRange == '30',
            onTap: () => manager.setDateRange('30'),
          ),
          const SizedBox(width: 8),
          WarmChip(
            label: '90d',
            selected: manager.dateRange == '90',
            onTap: () => manager.setDateRange('90'),
          ),
          const SizedBox(width: 8),
          WarmChip(
            label: '6mo',
            selected: manager.dateRange == '180',
            onTap: () => manager.setDateRange('180'),
          ),
          const SizedBox(width: 8),
          WarmChip(
            label:
                manager.dateRange == 'custom' && manager.customDateRange != null
                ? '${manager.customDateRange!.start.day}/${manager.customDateRange!.start.month} – ${manager.customDateRange!.end.day}/${manager.customDateRange!.end.month}'
                : 'Custom',
            selected: manager.dateRange == 'custom',
            onTap: onPickCustomDateRange,
          ),
          const SizedBox(width: 8),

          // ── All Filters button (with badge) ──
          ActionChip(
            avatar: Badge(
              isLabelVisible: activeFilterCount > 0,
              label: Text('$activeFilterCount'),
              child: const Icon(Icons.tune, size: 16),
            ),
            label: const Text('Filters'),
            onPressed: onShowFilterSheet,
          ),
        ],
      ),
    );
  }
}
