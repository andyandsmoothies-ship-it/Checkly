import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';

final _di = GetIt.instance;

/// Data snapshot for a single store's dashboard.
class StoreDashboardData {
  final String storeName;
  final double avgScore;
  final int openAPs;
  final List<CachedSubmission> recentAudits;

  const StoreDashboardData({
    required this.storeName,
    required this.avgScore,
    required this.openAPs,
    required this.recentAudits,
  });
}

/// PFA Manager for the Store Dashboard page.
///
/// Wraps all direct [AppDatabase] queries from the old [StoreDashboardPage]
/// into a proper Manager layer. Scoped by [storeId].
class StoreDashboardManager extends ChangeNotifier {
  final AppDatabase _db;

  StoreDashboardManager({AppDatabase? db})
    : _db = db ?? _di<DatabaseService>().db;

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  StoreDashboardData? data;

  // ---------- Load ----------
  /// Loads all store-scoped data. Call on page init and on refresh.
  ///
  /// OBS-8: All aggregates (avgScore, openAPs) computed in SQL.
  /// Only the 10 most-recent audit rows are loaded into memory.
  Future<void> load(String storeId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Store info
      final store =
          await (_db.select(_db.cachedStores)
                ..where((s) => s.id.equals(storeId))
                ..limit(1))
              .getSingleOrNull();
      final storeName = store?.name ?? 'Unknown Store';

      // ── Recent audits: SQL LIMIT 10 — no 1000-row load ──────────────────
      final recentAudits =
          await (_db.select(_db.cachedSubmissions)
                ..where((s) => s.storeId.equals(storeId))
                ..where((s) => s.reviewStatus.equals('rejected').not())
                ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
                ..limit(10))
              .get();

      // ── Average score: SQL avg() — no row hydration ──────────────────────
      final avgExp = _db.cachedSubmissions.totalScore.avg();
      final avgQuery = _db.selectOnly(_db.cachedSubmissions)
        ..addColumns([avgExp])
        ..where(_db.cachedSubmissions.storeId.equals(storeId))
        ..where(_db.cachedSubmissions.reviewStatus.equals('rejected').not());
      final avgScore =
          await avgQuery.map((r) => r.read(avgExp)).getSingle() ?? 0.0;

      // ── Open APs: SQL COUNT via subquery — no row hydration ──────────────
      final countExp = countAll();
      final openAPsQuery = _db.selectOnly(_db.cachedActionPlans)
        ..addColumns([countExp])
        ..where(_db.cachedActionPlans.status.equals('open'))
        ..where(
          _db.cachedActionPlans.submissionId.isInQuery(
            _db.selectOnly(_db.cachedSubmissions)
              ..addColumns([_db.cachedSubmissions.id])
              ..where(_db.cachedSubmissions.storeId.equals(storeId)),
          ),
        );
      final openAPs =
          await openAPsQuery.map((r) => r.read(countExp)).getSingle() ?? 0;

      data = StoreDashboardData(
        storeName: storeName,
        avgScore: avgScore,
        openAPs: openAPs,
        recentAudits: recentAudits,
      );
    } catch (e) {
      error = 'Failed to load store data';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
