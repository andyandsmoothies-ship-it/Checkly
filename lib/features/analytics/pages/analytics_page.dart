import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';

import '../manager/analytics_manager.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';

final _di = GetIt.instance;

/// 6C: Analytics page — 5 KPI cards + 6-month trend + filters.
/// Data sourced from local CachedSubmissions (filtered by reviewStatus != rejected).
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
      builder: (_) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedArea,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Areas'),
                      ),
                      ...(_manager.data?.areaNames ?? []).map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedArea = v;
                      _manager.selectedStore = null; // cascade reset
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedStore,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Store',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Stores'),
                      ),
                      ...(_manager.data?.storeNames ?? []).map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedStore = v;
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Audit Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...(_manager.data?.templateTypes ?? []).map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedType = v;
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedAuditor,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Auditor',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Auditors'),
                      ),
                      ...(_manager.data?.auditorNames ?? []).map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedAuditor = v;
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedStatus = v;
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _manager.selectedReviewStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Review Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Review Statuses'),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved'),
                      ),
                    ],
                    onChanged: (v) {
                      _manager.selectedReviewStatus = v;
                      Navigator.pop(context);
                      _manager.load();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      _manager.customDateRange = picked;
      _manager.dateRange = 'custom';
      _manager.load();
    }
  }

  // ── Active filter count (for badge) ──

  int get _activeFilterCount {
    int count = 0;
    if (_manager.selectedArea != null) count++;
    if (_manager.selectedStore != null) count++;
    if (_manager.selectedType != null) count++;
    if (_manager.selectedAuditor != null) count++;
    if (_manager.selectedStatus != null) count++;
    if (_manager.selectedReviewStatus != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          final theme = Theme.of(context);
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = _manager.data;
          final totalAudits = data?.totalAudits ?? 0;

          return RefreshIndicator(
            onRefresh: _manager.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Filter Chip Bar ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Active filter chips (dismissible)
                      if (_manager.selectedArea != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text('Area: ${_manager.selectedArea}'),
                            onDeleted: () {
                              _manager.selectedArea = null;
                              _manager.selectedStore = null;
                              _manager.load();
                            },
                          ),
                        ),
                      if (_manager.selectedStore != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_manager.selectedStore!),
                            onDeleted: () {
                              _manager.selectedStore = null;
                              _manager.load();
                            },
                          ),
                        ),
                      if (_manager.selectedType != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_manager.selectedType!),
                            onDeleted: () {
                              _manager.selectedType = null;
                              _manager.load();
                            },
                          ),
                        ),
                      if (_manager.selectedAuditor != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(_manager.selectedAuditor!),
                            onDeleted: () {
                              _manager.selectedAuditor = null;
                              _manager.load();
                            },
                          ),
                        ),
                      if (_manager.selectedStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(
                              _manager.selectedStatus == 'completed'
                                  ? 'Completed'
                                  : 'In Progress',
                            ),
                            onDeleted: () {
                              _manager.selectedStatus = null;
                              _manager.load();
                            },
                          ),
                        ),
                      if (_manager.selectedReviewStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: Text(
                              _manager.selectedReviewStatus == 'pending'
                                  ? 'Pending Review'
                                  : 'Approved',
                            ),
                            onDeleted: () {
                              _manager.selectedReviewStatus = null;
                              _manager.load();
                            },
                          ),
                        ),

                      // Date range chips
                      WarmChip(
                        label: 'All Time',
                        selected: _manager.dateRange == 'all',
                        onTap: () {
                          _manager.dateRange = 'all';
                          _manager.customDateRange = null;
                          _manager.load();
                        },
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label: '30d',
                        selected: _manager.dateRange == '30',
                        onTap: () {
                          _manager.dateRange = '30';
                          _manager.customDateRange = null;
                          _manager.load();
                        },
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label: '90d',
                        selected: _manager.dateRange == '90',
                        onTap: () {
                          _manager.dateRange = '90';
                          _manager.customDateRange = null;
                          _manager.load();
                        },
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label: '6mo',
                        selected: _manager.dateRange == '180',
                        onTap: () {
                          _manager.dateRange = '180';
                          _manager.customDateRange = null;
                          _manager.load();
                        },
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label:
                            _manager.dateRange == 'custom' &&
                                _manager.customDateRange != null
                            ? '${_manager.customDateRange!.start.day}/${_manager.customDateRange!.start.month} – ${_manager.customDateRange!.end.day}/${_manager.customDateRange!.end.month}'
                            : 'Custom',
                        selected: _manager.dateRange == 'custom',
                        onTap: _pickCustomDateRange,
                      ),
                      const SizedBox(width: 8),

                      // All Filters button (with badge)
                      ActionChip(
                        avatar: Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          child: const Icon(Icons.tune, size: 16),
                        ),
                        label: const Text('Filters'),
                        onPressed: _showFilterSheet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (totalAudits == 0 && _activeFilterCount > 0)
                  const ChecklyEmptyState(
                    icon: Icons.search_off,
                    title: 'No Match',
                    subtitle:
                        'No audits match your current filters. Clear filters to see more.',
                  )
                else if (totalAudits == 0)
                  const ChecklyEmptyState(
                    icon: Icons.analytics_outlined,
                    title: 'No analytics yet',
                    subtitle: 'Complete your first audit to generate insights.',
                  )
                else ...[
                  // KPI Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KpiCard(
                        icon: Icons.assignment,
                        label: 'Total Audits',
                        value: '$totalAudits',
                        accentColor: theme.colorScheme.primary,
                        tooltip: 'Total non-rejected audits',
                        onTap: () => context.go('/activity'),
                      ),
                      _KpiCard(
                        icon: Icons.speed,
                        label: 'Avg Audit Score',
                        value: '${(data?.avgScore ?? 0).toStringAsFixed(1)}%',
                        accentColor: AppTheme.success,
                        tooltip: 'Mean score of all scored audits',
                        onTap: () => context.go('/activity?filter=submitted'),
                      ),
                      _KpiCard(
                        icon: Icons.pending_actions,
                        label: 'Action Plans',
                        value: '${data?.openAPs ?? 0}',
                        accentColor: AppTheme.warning,
                        tooltip: 'Action plans awaiting resolution',
                        onTap: () => context.go('/plans?filter=open'),
                      ),
                      _KpiCard(
                        icon: Icons.warning_amber,
                        label: 'Overdue',
                        value: '${data?.overdueAPs ?? 0}',
                        accentColor: Theme.of(context).colorScheme.error,
                        tooltip: 'Action plans past their deadline',
                        onTap: () => context.go('/plans?sort=urgent'),
                      ),
                      _KpiCard(
                        icon: Icons.check_circle,
                        label: 'Completion',
                        value:
                            '${(data?.completionRate ?? 0).toStringAsFixed(1)}%',
                        accentColor: AppTheme.info,
                        onTap: () => context.go('/activity?filter=submitted'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const SectionHeader('6-MONTH TREND'),
                  TrendChart(
                    data: data?.trend ?? [],
                    onMonthTap: (month) => context.go('/activity?month=$month'),
                  ),

                  const SizedBox(height: 24),

                  const SectionHeader('CATEGORY PERFORMANCE'),
                  CategoryHeatmap(categories: data?.categoryScores ?? []),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final String? tooltip;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 40) / 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    const Spacer(),
                    if (tooltip != null)
                      Tooltip(
                        message: tooltip!,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppFonts.serifStyle(
                    fontSize: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.fontSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
