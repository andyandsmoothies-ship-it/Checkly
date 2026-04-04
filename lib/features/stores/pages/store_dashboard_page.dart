import 'package:flutter/material.dart';
import 'package:drift/drift.dart'
    hide Column; // Hide Column to avoid conflict with Flutter
import '../../../_shared/utils/date_format_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/theme/app_fonts.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/_shared/utils/score_utils.dart';
import 'package:get_it/get_it.dart';

/// 6C: Store Dashboard — single-store detail with audit history and AP summary.
///
/// Apothecary design: flat sage-bordered cards, serif accent numbers,
/// Manrope labels, warm cream background.
class StoreDashboardPage extends StatefulWidget {
  final String storeId;
  const StoreDashboardPage({super.key, required this.storeId});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  late final AppDatabase _db;
  bool _loading = true;

  String _storeName = '';
  double _avgScore = 0;
  int _openAPs = 0;
  List<CachedSubmission> _recentAudits = [];

  @override
  void initState() {
    super.initState();
    _db = GetIt.I<DatabaseService>().db;
    _loadData();
  }

  Future<void> _loadData() async {
    // Store info
    final store =
        await (_db.select(_db.cachedStores)
              ..where((s) => s.id.equals(widget.storeId))
              ..limit(1)) // Bounded for memory safety (Gotcha #14)
            .getSingleOrNull();
    _storeName = store?.name ?? 'Unknown Store';

    // Submissions for this store - Filtered in DB
    final storeSubs =
        await (_db.select(_db.cachedSubmissions)
              ..where((s) => s.storeId.equals(widget.storeId))
              ..where((s) => s.reviewStatus.equals('rejected').not())
              ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
              ..limit(
                1000,
              )) // Bounded to 1000 history items for mobile (Gotcha #14)
            .get();

    _recentAudits = storeSubs.take(10).toList();

    final scored = storeSubs.where((s) => s.totalScore != null).toList();
    _avgScore = scored.isNotEmpty
        ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) /
              scored.length
        : 0;

    // Open APs for this store - Filtered in DB using submission subquery
    final openAPsQuery = _db.select(_db.cachedActionPlans)
      ..where((ap) => ap.status.equals('open'))
      ..where(
        (ap) => ap.submissionId.isInQuery(
          _db.selectOnly(_db.cachedSubmissions)
            ..addColumns([_db.cachedSubmissions.id])
            ..where(_db.cachedSubmissions.storeId.equals(widget.storeId)),
        ),
      )
      ..limit(1000); // Bounded for memory safety (Gotcha #14)

    final openAPList = await openAPsQuery.get();
    _openAPs = openAPList.length;

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
                // ── Score overview card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.sageGray.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Trailing 6-Month Avg Audit Score',
                        style: AppFonts.displayStyle(
                          fontSize: theme.textTheme.labelSmall?.fontSize,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_avgScore.toStringAsFixed(1)}%',
                        style: AppFonts.serifStyle(
                          fontSize: theme.textTheme.displaySmall?.fontSize ?? 40,
                          fontWeight: FontWeight.w700,
                          color: scoreColor(_avgScore, Theme.of(context)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MetricChip(
                            label: 'Activities',
                            value: '${_recentAudits.length}',
                            icon: Icons.assignment_outlined,
                          ),
                          const SizedBox(width: 20),
                          _MetricChip(
                            label: 'Action Plans',
                            value: '$_openAPs',
                            icon: Icons.pending_actions_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Recent Audits header ──
                Text(
                  'RECENT AUDITS',
                  style: AppFonts.displayStyle(
                    fontSize: theme.textTheme.labelSmall?.fontSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Audit list ──
                if (_recentAudits.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.sageGray.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No audits found for this store.',
                        style: AppFonts.displayStyle(
                          fontSize: theme.textTheme.bodyMedium?.fontSize,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(_recentAudits.length, (i) {
                    final s = _recentAudits[i];
                    final score = s.totalScore ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.sageGray.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scoreColor(
                              score,
                              Theme.of(context),
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${score.toStringAsFixed(0)}%',
                            style: AppFonts.serifStyle(
                              fontSize: theme.textTheme.labelSmall?.fontSize ?? 13,
                              fontWeight: FontWeight.w700,
                              color: scoreColor(score, Theme.of(context)),
                            ),
                          ),
                        ),
                        title: Text(
                          s.templateTitle ?? 'Audit',
                          style: AppFonts.displayStyle(
                            fontSize: theme.textTheme.bodyMedium?.fontSize,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${s.auditorName ?? 'Unknown'} • ${_formatDate(s.createdAt)}',
                          style: AppFonts.displayStyle(
                            fontSize: theme.textTheme.bodySmall?.fontSize,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    );
                  }),

                // View All History button
                if (_recentAudits.isNotEmpty)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/activity'),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('View All History'),
                    ),
                  ),
              ],
            ),
    );
  }

  String _formatDate(DateTime dt) => formatDate(dt);
}

/// Metric chip with icon + label — Apothecary style.
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
        Icon(icon, size: 16, color: AppTheme.sageGray),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: AppFonts.displayStyle(
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
