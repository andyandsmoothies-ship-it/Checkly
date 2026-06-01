import 'package:flutter/material.dart';

import '../../../_shared/theme/app_colors.dart';
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

          // ── Date range selection pill ──
          DropdownFilterPill(
            label: 'Date',
            value: switch (manager.dateRange) {
              'all' => 'All Time',
              '30' => '30d',
              '90' => '90d',
              '180' => '6mo',
              'custom' => manager.customDateRange != null
                  ? '${manager.customDateRange!.start.day}/${manager.customDateRange!.start.month} – ${manager.customDateRange!.end.day}/${manager.customDateRange!.end.month}'
                  : 'Custom',
              _ => 'All Time',
            },
            active: manager.dateRange != 'all',
            onTap: () => showAnalyticsDateRangeFilterSheet(
              context: context,
              manager: manager,
              onPickCustomDateRange: onPickCustomDateRange,
            ),
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

class DropdownFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const DropdownFilterPill({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(
                color: active ? Colors.white : AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.eel,
            ),
          ],
        ),
      ),
    );
  }
}

void showAnalyticsDateRangeFilterSheet({
  required BuildContext context,
  required AnalyticsManager manager,
  required VoidCallback onPickCustomDateRange,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final options = [
        {'id': 'all', 'label': 'All Time'},
        {'id': '30', 'label': 'Last 30 Days'},
        {'id': '90', 'label': 'Last 90 Days'},
        {'id': '180', 'label': 'Last 6 Months'},
        {'id': 'custom', 'label': 'Custom Range...'},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...options.map((opt) {
                final isSelected = manager.dateRange == opt['id'];
                return InkWell(
                  onTap: () {
                    Navigator.maybePop(ctx);
                    if (opt['id'] == 'custom') {
                      onPickCustomDateRange();
                    } else {
                      manager.setDateRange(opt['id'] as String);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.featherGreen.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.featherGreen : AppColors.eel,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
