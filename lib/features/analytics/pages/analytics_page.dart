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

  // Filters
  String? _selectedStore;
  String? _selectedType;
  String _dateRange = 'all'; // all, 30, 90, 180
  List<String> _storeNames = [];
  List<String> _templateTypes = [];

  // KPIs
  int _totalAudits = 0;
  double _avgScore = 0;
  int _openAPs = 0;
  int _overdueAPs = 0;
  double _completionRate = 0;

  // Trend data
  List<TrendPoint> _trend = [];

  // Category heatmap data
  List<CategoryScore> _categoryScores = [];

  @override
  void initState() {
    super.initState();
    _db = GetIt.I<DatabaseService>().db;
    _loadData();
  }

  Future<void> _loadData() async {
    final allSubs = await _db.select(_db.cachedSubmissions).get();
    var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

    // Build filter options from cached master data (always fully populated)
    final allStores = await _db.select(_db.cachedStores).get();
    _storeNames = allStores.map((s) => s.name).toSet().toList()..sort();
    final templates = await _db.select(_db.cachedTemplates).get();
    _templateTypes = templates.map((t) => t.type).toSet().toList()..sort();
    final templateTypeMap = <String, String>{};
    for (final t in templates) {
      templateTypeMap[t.id] = t.type;
    }

    // Apply store filter
    if (_selectedStore != null) {
      subs = subs.where((s) => s.storeName == _selectedStore).toList();
    }

    // Apply type filter
    if (_selectedType != null) {
      final typeTemplateIds = templates
          .where((t) => t.type == _selectedType)
          .map((t) => t.id)
          .toSet();
      subs = subs.where((s) => typeTemplateIds.contains(s.templateId)).toList();
    }

    // Apply date range filter
    final now = DateTime.now();
    if (_dateRange != 'all') {
      final days = int.parse(_dateRange);
      final cutoff = now.subtract(Duration(days: days));
      subs = subs.where((s) => s.createdAt.isAfter(cutoff)).toList();
    }

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
    final aps = await _db.select(_db.cachedActionPlans).get();
    _openAPs = aps.where((ap) => ap.status == 'open').length;
    _overdueAPs = aps
        .where(
          (ap) =>
              ap.status == 'open' &&
              ap.deadline != null &&
              ap.deadline!.isBefore(now),
        )
        .length;

    // 6-month trend — padded to always show 6 months
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

    // Build exactly 6 month keys for continuous X-axis
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

    // Category heatmap — group by template type
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStore,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Store',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Stores')),
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
            DropdownButtonFormField<String>(
              value: _selectedType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Audit Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
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
          ],
        ),
      ),
    );
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
                        // Active filter chips
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
                        // Date range chips
                        WarmChip(
                          label: 'All Time',
                          selected: _dateRange == 'all',
                          onTap: () {
                            _dateRange = 'all';
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
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        // All Filters button
                        ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
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
                        ),
                        _KpiCard(
                          icon: Icons.speed,
                          label: 'Avg Score',
                          value: '${_avgScore.toStringAsFixed(1)}%',
                          accentColor: AppTheme.success,
                          tooltip: 'Mean score of all scored audits',
                        ),
                        _KpiCard(
                          icon: Icons.pending_actions,
                          label: 'Open APs',
                          value: '$_openAPs',
                          accentColor: AppTheme.warning,
                          tooltip: 'Action plans awaiting resolution',
                        ),
                        _KpiCard(
                          icon: Icons.warning_amber,
                          label: 'Overdue',
                          value: '$_overdueAPs',
                          accentColor: Colors.red,
                          tooltip: 'Action plans past their deadline',
                        ),
                        _KpiCard(
                          icon: Icons.check_circle,
                          label: 'Completion',
                          value: '${_completionRate.toStringAsFixed(1)}%',
                          accentColor: AppTheme.info,
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

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 40) / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.3)),
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
    );
  }
}
