import 'package:drift/drift.dart';

import '../../../_shared/database/app_database.dart';

/// Drift aggregate query helpers for the dashboard.
///
/// All queries use Drift expressions (count, where, limit) to avoid
/// loading full tables into memory (Anti-OOM pattern).
class DashboardQueries {
  final AppDatabase _db;

  const DashboardQueries(this._db);

  // ── Auditor queries ──────────────────────────────────────────────

  /// Count of submissions in 'draft' status (the auditor's in-progress audits).
  Future<int> getDraftCount() async {
    final count = _db.cachedSubmissions.id.count();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([count])
      ..where(_db.cachedSubmissions.status.equals('draft'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Count of open or pending_verify APs (global, for auditor/admin view).
  Future<int> getMyOpenApCount() async {
    final count = _db.cachedActionPlans.id.count();
    final query = _db.selectOnly(_db.cachedActionPlans)
      ..addColumns([count])
      ..where(_db.cachedActionPlans.status.isIn(['open', 'pending_verify']));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Average score across all non-null scored submissions for the current user.
  Future<double> getMyAvgScore() async {
    final avg = _db.cachedSubmissions.totalScore.avg();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([avg])
      ..where(_db.cachedSubmissions.totalScore.isNotNull());
    final row = await query.getSingle();
    return row.read(avg) ?? 0.0;
  }

  /// Nearest future deadline across open APs.
  Future<DateTime?> getNearestDeadline() async {
    final now = DateTime.now();
    final rows =
        await (_db.select(_db.cachedActionPlans)
              ..where((a) => a.status.equals('open') & a.deadline.isNotNull())
              ..orderBy([(a) => OrderingTerm.asc(a.deadline)])
              ..limit(1))
            .get();
    if (rows.isEmpty) return null;
    final d = rows.first.deadline;
    return (d != null && d.isAfter(now)) ? d : null;
  }

  /// Last N submissions sorted by createdAt desc (for activity feed).
  Future<List<CachedSubmission>> getRecentSubmissions({int limit = 10}) async {
    return (_db.select(_db.cachedSubmissions)
          ..where((s) => s.reviewStatus.isNotValue('rejected'))
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
          ..limit(limit))
        .get();
  }

  // ── Store / Area Manager queries ─────────────────────────────────

  /// Count of open APs for a specific store.
  Future<int> getOpenApCountForStore(String storeId) async {
    final count = _db.cachedActionPlans.id.count();
    final query = _db.selectOnly(_db.cachedActionPlans)
      ..addColumns([count])
      ..where(
        _db.cachedActionPlans.storeId.equals(storeId) &
            _db.cachedActionPlans.status.isIn(['open', 'pending_verify']),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Count of overdue APs for a specific store.
  /// Uses selectOnly+count — no rows are loaded into Dart memory.
  Future<int> getOverdueApCountForStore(String storeId) async {
    final now = DateTime.now();
    final count = _db.cachedActionPlans.id.count();
    final query = _db.selectOnly(_db.cachedActionPlans)
      ..addColumns([count])
      ..where(
        _db.cachedActionPlans.storeId.equals(storeId) &
            _db.cachedActionPlans.status.equals('open') &
            _db.cachedActionPlans.deadline.isSmallerThanValue(now),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Average score for submissions belonging to a specific store.
  Future<double> getAvgScoreForStore(String storeId) async {
    final avg = _db.cachedSubmissions.totalScore.avg();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([avg])
      ..where(
        _db.cachedSubmissions.storeId.equals(storeId) &
            _db.cachedSubmissions.totalScore.isNotNull(),
      );
    final row = await query.getSingle();
    return (row.read(avg) ?? 0.0).toDouble();
  }

  // ── Admin queries ─────────────────────────────────────────────────

  /// Count of all non-rejected submissions (total audit count).
  Future<int> getTotalAuditCount() async {
    final count = _db.cachedSubmissions.id.count();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([count])
      ..where(_db.cachedSubmissions.reviewStatus.isNotValue('rejected'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Global average score across all scored submissions.
  Future<double> getGlobalAvgScore() async {
    final avg = _db.cachedSubmissions.totalScore.avg();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([avg])
      ..where(_db.cachedSubmissions.totalScore.isNotNull());
    final row = await query.getSingle();
    return (row.read(avg) ?? 0.0).toDouble();
  }

  /// Count of stores with average score below 80% ("weak stores").
  ///
  /// Executes a raw SQL GROUP BY + HAVING AVG query entirely in SQLite.
  /// Drift 2.x does not expose .having() on selectOnly — customSelect
  /// is the documented pattern for aggregate HAVING clauses.
  /// Only the count of matching store IDs is returned; zero submission
  /// rows are materialized in Dart memory.
  Future<int> getWeakStoreCount() async {
    const sql = '''
      SELECT store_id
      FROM cached_submissions
      WHERE store_id IS NOT NULL
        AND total_score IS NOT NULL
      GROUP BY store_id
      HAVING AVG(total_score) < 80
    ''';
    final rows = await _db.customSelect(sql).get();
    return rows.length;
  }

  /// Count of all open APs (admin view).
  Future<int> getGlobalOpenApCount() async {
    final count = _db.cachedActionPlans.id.count();
    final query = _db.selectOnly(_db.cachedActionPlans)
      ..addColumns([count])
      ..where(_db.cachedActionPlans.status.isIn(['open', 'pending_verify']));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Count of all overdue APs across the platform (admin view).
  /// Uses selectOnly+count — no rows are loaded into Dart memory.
  Future<int> getGlobalOverdueApCount() async {
    final now = DateTime.now();
    final count = _db.cachedActionPlans.id.count();
    final query = _db.selectOnly(_db.cachedActionPlans)
      ..addColumns([count])
      ..where(
        _db.cachedActionPlans.status.equals('open') &
            _db.cachedActionPlans.deadline.isSmallerThanValue(now),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Count of submissions completed this calendar month.
  Future<int> getMonthlyCompletedCount() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final count = _db.cachedSubmissions.id.count();
    final query = _db.selectOnly(_db.cachedSubmissions)
      ..addColumns([count])
      ..where(
        _db.cachedSubmissions.status.equals('completed') &
            _db.cachedSubmissions.createdAt.isBiggerThanValue(monthStart),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Total possible audits this month (templates × stores).
  Future<int> getMonthlyTotal() async {
    final templates = await (_db.selectOnly(
      _db.cachedTemplates,
    )..addColumns([_db.cachedTemplates.id.count()])).getSingle();
    final stores = await (_db.selectOnly(
      _db.cachedStores,
    )..addColumns([_db.cachedStores.id.count()])).getSingle();

    final tCount = templates.read(_db.cachedTemplates.id.count()) ?? 0;
    final sCount = stores.read(_db.cachedStores.id.count()) ?? 0;
    final total = tCount * sCount;
    return total > 0 ? total : 1;
  }
}
