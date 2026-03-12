import 'package:flutter/material.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// 6C: Store Dashboard — single-store detail with audit history and AP summary.
class StoreDashboardPage extends StatefulWidget {
  final String storeId;
  const StoreDashboardPage({super.key, required this.storeId});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  final _db = GetIt.I<AppDatabase>();
  bool _loading = true;

  String _storeName = '';
  double _avgScore = 0;
  int _openAPs = 0;
  List<CachedSubmission> _recentAudits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Store info
    final stores = await _db.select(_db.cachedStores).get();
    final store = stores.where((s) => s.id == widget.storeId).firstOrNull;
    _storeName = store?.name ?? 'Unknown Store';

    // Submissions for this store
    final allSubs = await _db.select(_db.cachedSubmissions).get();
    final storeSubs =
        allSubs
            .where(
              (s) =>
                  s.storeId == widget.storeId && s.reviewStatus != 'rejected',
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _recentAudits = storeSubs.take(10).toList();

    final scored = storeSubs.where((s) => s.totalScore != null).toList();
    _avgScore = scored.isNotEmpty
        ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) /
              scored.length
        : 0;

    // APs for this store
    final aps = await _db.select(_db.cachedActionPlans).get();
    _openAPs = aps
        .where(
          (ap) =>
              ap.status == 'open' &&
              ap.submissionId != null &&
              storeSubs.any((s) => s.id == ap.submissionId),
        )
        .length;

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_storeName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Score gauge card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Average Score',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_avgScore.toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _avgScore >= 80
                                ? AppTheme.success
                                : _avgScore >= 60
                                ? AppTheme.warning
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _MetricChip(
                              label: 'Audits',
                              value: '${_recentAudits.length}',
                              icon: Icons.assignment,
                            ),
                            const SizedBox(width: 16),
                            _MetricChip(
                              label: 'Open APs',
                              value: '$_openAPs',
                              icon: Icons.pending_actions,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Text('Recent Audits', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),

                if (_recentAudits.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No audits found for this store.'),
                    ),
                  )
                else
                  ...List.generate(_recentAudits.length, (i) {
                    final s = _recentAudits[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (s.totalScore ?? 0) >= 80
                              ? AppTheme.success.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          child: Text(
                            '${(s.totalScore ?? 0).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (s.totalScore ?? 0) >= 80
                                  ? AppTheme.success
                                  : Colors.red,
                            ),
                          ),
                        ),
                        title: Text(s.templateTitle ?? 'Audit'),
                        subtitle: Text(
                          '${s.auditorName ?? 'Unknown'} • ${_formatDate(s.createdAt)}',
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text('$value $label', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
