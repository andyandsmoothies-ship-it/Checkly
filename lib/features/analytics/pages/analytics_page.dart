import 'package:flutter/material.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
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
  final _db = GetIt.I<AppDatabase>();
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
    _loadData();
  }

  Future<void> _loadData() async {
    final allSubs = await _db.select(_db.cachedSubmissions).get();
    var subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

    // Build filter options from all data (before filtering)
    _storeNames = subs.map((s) => s.storeName ?? 'Unknown').toSet().toList()
      ..sort();
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

    // 6-month trend
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

    _trend = grouped.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return TrendPoint(e.key, avg, e.value.length);
    }).toList()..sort((a, b) => a.month.compareTo(b.month));

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
                  // ── Filter Dropdowns ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Store filter
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 40) / 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedStore,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Store',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                      ),
                      // Type filter
                      SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 40) / 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date range chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _DateChip(
                          label: 'All Time',
                          value: 'all',
                          selected: _dateRange == 'all',
                          onTap: () {
                            _dateRange = 'all';
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          label: '30 Days',
                          value: '30',
                          selected: _dateRange == '30',
                          onTap: () {
                            _dateRange = '30';
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          label: '90 Days',
                          value: '90',
                          selected: _dateRange == '90',
                          onTap: () {
                            _dateRange = '90';
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                        const SizedBox(width: 8),
                        _DateChip(
                          label: '6 Months',
                          value: '180',
                          selected: _dateRange == '180',
                          onTap: () {
                            _dateRange = '180';
                            setState(() => _loading = true);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KPI Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KpiCard(
                        icon: Icons.assignment,
                        label: 'Total Audits',
                        value: '$_totalAudits',
                        color: theme.colorScheme.primary,
                      ),
                      _KpiCard(
                        icon: Icons.speed,
                        label: 'Avg Score',
                        value: '${_avgScore.toStringAsFixed(1)}%',
                        color: AppTheme.success,
                      ),
                      _KpiCard(
                        icon: Icons.pending_actions,
                        label: 'Open APs',
                        value: '$_openAPs',
                        color: AppTheme.warning,
                      ),
                      _KpiCard(
                        icon: Icons.warning_amber,
                        label: 'Overdue',
                        value: '$_overdueAPs',
                        color: Colors.red,
                      ),
                      _KpiCard(
                        icon: Icons.check_circle,
                        label: 'Completion',
                        value: '${_completionRate.toStringAsFixed(1)}%',
                        color: AppTheme.info,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Trend section header
                  Text('6-Month Trend', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Trend chart (fl_chart LineChart)
                  TrendChart(data: _trend),

                  const SizedBox(height: 24),

                  // Category heatmap
                  CategoryHeatmap(categories: _categoryScores),
                ],
              ),
            ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 40) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
