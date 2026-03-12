import 'package:flutter/material.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

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

  // KPIs
  int _totalAudits = 0;
  double _avgScore = 0;
  int _openAPs = 0;
  int _overdueAPs = 0;
  double _completionRate = 0;

  // Trend data
  List<_TrendPoint> _trend = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allSubs = await _db.select(_db.cachedSubmissions).get();
    final subs = allSubs.where((s) => s.reviewStatus != 'rejected').toList();

    final now = DateTime.now();

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
      return _TrendPoint(e.key, avg, e.value.length);
    }).toList()..sort((a, b) => a.month.compareTo(b.month));

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

                  // Simple trend bars (fl_chart dependency not added — using cards)
                  if (_trend.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No trend data available yet.'),
                      ),
                    )
                  else
                    ..._trend.map((t) => _TrendBar(point: t)),
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

class _TrendBar extends StatelessWidget {
  final _TrendPoint point;
  const _TrendBar({required this.point});

  @override
  Widget build(BuildContext context) {
    final pct = (point.avgScore / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              point.month,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 16,
              borderRadius: BorderRadius.circular(4),
              color: pct > 0.8
                  ? AppTheme.success
                  : pct > 0.6
                  ? AppTheme.warning
                  : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${point.avgScore.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final String month;
  final double avgScore;
  final int count;
  _TrendPoint(this.month, this.avgScore, this.count);
}
