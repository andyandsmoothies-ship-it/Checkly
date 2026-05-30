import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../manager/analytics_manager.dart';
import '../widgets/analytics_filter_sheet.dart';
import 'analytics_body.dart';
import 'analytics_filter_chips.dart';

final _di = GetIt.instance;

/// 6C: Analytics page — 5 KPI cards + 6-month trend + filters.
/// Data sourced from local CachedSubmissions (filtered by reviewStatus != rejected).
///
/// Layout responsibility is split into:
/// - [AnalyticsFilterChips] — scrollable chip bar
/// - [AnalyticsBody]        — offline banner + empty states + all content sections
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final AnalyticsManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<AnalyticsManager>();
    _manager.load();
  }

  // ── Filter Sheet ──

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnalyticsFilterSheet(manager: _manager),
    );
  }

  // ── Custom Date Range ──

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _manager.customDateRange,
    );
    if (picked != null) {
      _manager.setDateRange('custom', custom: picked);
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_manager.selectedProvince != null) count++;
    if (_manager.selectedStore != null) count++;
    if (_manager.selectedType != null) count++;
    if (_manager.selectedAuditor != null) count++;
    if (_manager.selectedStatus != null) count++;
    if (_manager.selectedReviewStatus != null) count++;
    if (_manager.selectedCategoryTag != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return AnalyticsBody(
            manager: _manager,
            activeFilterCount: _activeFilterCount,
            filterChips: AnalyticsFilterChips(
              manager: _manager,
              activeFilterCount: _activeFilterCount,
              onShowFilterSheet: _showFilterSheet,
              onPickCustomDateRange: _pickCustomDateRange,
            ),
          );
        },
      ),
    );
  }
}
