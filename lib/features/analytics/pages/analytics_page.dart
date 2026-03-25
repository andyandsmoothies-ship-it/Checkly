import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/_shared/theme/app_fonts.dart';
import 'package:checkly/_shared/widgets/warm_chip.dart';
import 'package:checkly/_shared/widgets/section_header.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:get_it/get_it.dart';

import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';

/// 6C: Analytics page — 5 KPI cards + 6-month trend + filters.
/// Data sourced from local CachedSubmissions (filtered by reviewStatus != rejected).
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final AppDatabase _db;
  bool _loading = true;

  // ── Filters ──
  String? _selectedStore;
  String? _selectedType;
  String? _selectedArea;
  String? _selectedAuditor;
  String? _selectedStatus; // 'completed' | 'in_progress'
  String? _selectedReviewStatus; // 'pending' | 'approved'
  String _dateRange = 'all'; // all, 30, 90, 180, custom
  DateTimeRange? _customDateRange;

  // ── Filter option lists ──
  List<String> _storeNames = [];
  List<String> _templateTypes = [];
  List<String> _areaNames = [];
  List<String> _auditorNames = [];

  // ── KPIs ──
  int _totalAudits = 0;
  double _avgScore = 0;
  int _openAPs = 0;
  int _overdueAPs = 0;
  double _completionRate = 0;

  // ── Trend data ──
  List<TrendPoint> _trend = [];

  // ── Category heatmap data ──
  List<CategoryScore> _categoryScores = [];

  @override
  void initState() {
    super.initState();
    _db = GetIt.I<DatabaseService>().db;
    _loadData();
  }

  Future<void> _loadData() async {
    final allSubs =
        await (_db.select(_db.cachedSubmissions)
              ..limit(1000)) // Bounded for memory safety (Gotcha #14)
            .get();
    var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

    // Build filter options from cached master data
    final allStores =
        await (_db.select(_db.cachedStores)
              ..limit(1000)) // Bounded for memory safety (Gotcha #14)
            .get();
    _areaNames =
        allStores
            .map((s) => s.areaName)
            .where((a) => a != null)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    // Area → Store cascade: if area selected, restrict stores to that area
    final filteredStores = _selectedArea != null
        ? allStores.where((s) => s.areaName == _selectedArea).toList()
        : allStores;

    _storeNames = filteredStores.map((s) => s.name).toSet().toList()..sort();

    // Reset store if it's no longer valid after area change
    if (_selectedStore != null && !_storeNames.contains(_selectedStore)) {
      _selectedStore = null;
    }

    final templates =
        await (_db.select(_db.cachedTemplates)
              ..limit(500)) // Bounded for memory safety (Gotcha #14)
            .get();
    _templateTypes = templates.map((t) => t.type).toSet().toList()..sort();
    final templateTypeMap = <String, String>{};
    for (final t in templates) {
      templateTypeMap[t.id] = t.type;
    }

    // Build auditor list from submissions
    _auditorNames =
        subs
            .map((s) => s.auditorName)
            .where((a) => a != null)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    // ── Apply filters ──

    // Area filter (via store set for O(1) lookups)
    if (_selectedArea != null) {
      final areaStoreNames = filteredStores.map((s) => s.name).toSet();
      subs = subs.where((s) => areaStoreNames.contains(s.storeName)).toList();
    }

    // Store filter
    if (_selectedStore != null) {
      subs = subs.where((s) => s.storeName == _selectedStore).toList();
    }

    // Type filter
    if (_selectedType != null) {
      final typeTemplateIds = templates
          .where((t) => t.type == _selectedType)
          .map((t) => t.id)
          .toSet();
      subs = subs.where((s) => typeTemplateIds.contains(s.templateId)).toList();
    }

    // Auditor filter
    if (_selectedAuditor != null) {
      subs = subs.where((s) => s.auditorName == _selectedAuditor).toList();
    }

    // Status filter
    if (_selectedStatus != null) {
      subs = subs.where((s) => s.status == _selectedStatus).toList();
    }

    // Review status filter
    if (_selectedReviewStatus != null) {
      subs = subs
          .where((s) => s.reviewStatus == _selectedReviewStatus)
          .toList();
    }

    // Date range filter
    final now = DateTime.now();
    if (_dateRange == 'custom' && _customDateRange != null) {
      subs = subs
          .where(
            (s) =>
                s.createdAt.isAfter(_customDateRange!.start) &&
                s.createdAt.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    } else if (_dateRange != 'all') {
      final days = int.parse(_dateRange);
      final cutoff = now.subtract(Duration(days: days));
      subs = subs.where((s) => s.createdAt.isAfter(cutoff)).toList();
    }

    // ── Compute KPIs ──

    _totalAudits = subs.length;
    final scored = subs.where((s) => s.totalScore != null).toList();
    _avgScore = scored.isNotEmpty
        ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) /
              scored.length
        : 0;

    final completed = subs.where((s) => s.status == 'completed').toList();
    _completionRate = _totalAudits > 0
        ? completed.length / _totalAudits * 100
        : 0;

    // APs
    final aps =
        await (_db.select(_db.cachedActionPlans)
              ..limit(1000)) // Bounded for memory safety (Gotcha #14)
            .get();
    _openAPs = aps.where((ap) => ap.status == 'open').length;
    _overdueAPs = aps
        .where(
          (ap) =>
              ap.status == 'open' &&
              ap.deadline != null &&
              ap.deadline!.isBefore(now),
        )
        .length;

    // ── 6-month trend ──
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    final recentSubs = subs
        .where((s) => s.totalScore != null && s.createdAt.isAfter(sixMonthsAgo))
        .toList();

    final grouped = <String, List<double>>{};
    for (final s in recentSubs) {
      final key =
          '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s.totalScore!);
    }

    final monthKeys = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    }).reversed.toList();

    _trend = monthKeys.map((key) {
      final scores = grouped[key];
      if (scores != null && scores.isNotEmpty) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        return TrendPoint(key, avg, scores.length);
      }
      return TrendPoint(key, 0, 0);
    }).toList();

    // ── Category heatmap ──
    final catScores = <String, List<double>>{};
    for (final s in subs) {
      final type = templateTypeMap[s.templateId];
      if (type != null && s.totalScore != null) {
        catScores.putIfAbsent(type, () => []).add(s.totalScore!);
      }
    }
    _categoryScores = catScores.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return CategoryScore(
        name: e.key,
        avgScore: avg,
        auditCount: e.value.length,
      );
    }).toList();

    setState(() => _loading = false);
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

                  // Area dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
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
                      ..._areaNames.map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _selectedArea = v;
                      // Reset store when area changes (cascade)
                      _selectedStore = null;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Store dropdown (filtered by area)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStore,
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
                      ..._storeNames.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _selectedStore = v;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Audit Type dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
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
                      ..._templateTypes.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _selectedType = v;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Auditor dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAuditor,
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
                      ..._auditorNames.map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _selectedAuditor = v;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Status dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
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
                      _selectedStatus = v;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Review Status dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReviewStatus,
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
                      _selectedReviewStatus = v;
                      Navigator.pop(context);
                      setState(() => _loading = true);
                      _loadData();
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
      initialDateRange: _customDateRange,
    );
    if (picked != null) {
      _customDateRange = picked;
      _dateRange = 'custom';
      setState(() => _loading = true);
      _loadData();
    }
  }

  // ── Active filter count (for badge) ──

  int get _activeFilterCount {
    int count = 0;
    if (_selectedArea != null) count++;
    if (_selectedStore != null) count++;
    if (_selectedType != null) count++;
    if (_selectedAuditor != null) count++;
    if (_selectedStatus != null) count++;
    if (_selectedReviewStatus != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Filter Chip Bar ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Active filter chips (dismissible)
                        if (_selectedArea != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text('Area: $_selectedArea'),
                              onDeleted: () {
                                _selectedArea = null;
                                _selectedStore = null; // cascade reset
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),
                        if (_selectedStore != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(_selectedStore!),
                              onDeleted: () {
                                _selectedStore = null;
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),
                        if (_selectedType != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(_selectedType!),
                              onDeleted: () {
                                _selectedType = null;
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),
                        if (_selectedAuditor != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(_selectedAuditor!),
                              onDeleted: () {
                                _selectedAuditor = null;
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),
                        if (_selectedStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(
                                _selectedStatus == 'completed'
                                    ? 'Completed'
                                    : 'In Progress',
                              ),
                              onDeleted: () {
                                _selectedStatus = null;
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),
                        if (_selectedReviewStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(
                                _selectedReviewStatus == 'pending'
                                    ? 'Pending Review'
                                    : 'Approved',
                              ),
                              onDeleted: () {
                                _selectedReviewStatus = null;
                                setState(() => _loading = true);
                                _loadData();
                              },
                            ),
                          ),

                        // Date range chips
                        WarmChip(
                          label: 'All Time',
                          selected: _dateRange == 'all',
                          onTap: () {
                            _dateRange = 'all';
                            _customDateRange = null;
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        WarmChip(
                          label: '30d',
                          selected: _dateRange == '30',
                          onTap: () {
                            _dateRange = '30';
                            _customDateRange = null;
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        WarmChip(
                          label: '90d',
                          selected: _dateRange == '90',
                          onTap: () {
                            _dateRange = '90';
                            _customDateRange = null;
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        WarmChip(
                          label: '6mo',
                          selected: _dateRange == '180',
                          onTap: () {
                            _dateRange = '180';
                            _customDateRange = null;
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        WarmChip(
                          label:
                              _dateRange == 'custom' && _customDateRange != null
                              ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} – ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                              : 'Custom',
                          selected: _dateRange == 'custom',
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

                  if (_totalAudits == 0)
                    const ChecklyEmptyState(
                      icon: Icons.analytics_outlined,
                      title: 'No analytics yet',
                      subtitle:
                          'Complete your first audit to generate insights.',
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
                          value: '$_totalAudits',
                          accentColor: theme.colorScheme.primary,
                          tooltip: 'Total non-rejected audits',
                          onTap: () => context.go('/activity'),
                        ),
                        _KpiCard(
                          icon: Icons.speed,
                          label: 'Avg Audit Score',
                          value: '${_avgScore.toStringAsFixed(1)}%',
                          accentColor: AppTheme.success,
                          tooltip: 'Mean score of all scored audits',
                          onTap: () => context.go('/activity?filter=submitted'),
                        ),
                        _KpiCard(
                          icon: Icons.pending_actions,
                          label: 'Action Plans',
                          value: '$_openAPs',
                          accentColor: AppTheme.warning,
                          tooltip: 'Action plans awaiting resolution',
                          onTap: () => context.go('/plans?filter=open'),
                        ),
                        _KpiCard(
                          icon: Icons.warning_amber,
                          label: 'Overdue',
                          value: '$_overdueAPs',
                          accentColor: Colors.red,
                          tooltip: 'Action plans past their deadline',
                          onTap: () => context.go('/plans?sort=urgent'),
                        ),
                        _KpiCard(
                          icon: Icons.check_circle,
                          label: 'Completion',
                          value: '${_completionRate.toStringAsFixed(1)}%',
                          accentColor: AppTheme.info,
                          onTap: () => context.go('/activity?filter=submitted'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Trend section header
                    const SectionHeader('6-MONTH TREND'),

                    // Trend chart (fl_chart LineChart)
                    TrendChart(
                      data: _trend,
                      onMonthTap: (month) =>
                          context.go('/activity?month=$month'),
                    ),

                    const SizedBox(height: 24),

                    // Category heatmap
                    const SectionHeader('CATEGORY PERFORMANCE'),
                    CategoryHeatmap(categories: _categoryScores),
                  ],
                ],
              ),
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
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.sageGray.withValues(alpha: 0.3),
              ),
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
                          color: AppTheme.charcoal.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppFonts.serifStyle(
                    fontSize: 28,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: AppFonts.displayStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal.withValues(alpha: 0.5),
                    letterSpacing: 1,
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
