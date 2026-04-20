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
  Future<void> load(String storeId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Store info
      final store =
          await (_db.select(_db.cachedStores)
                ..where((s) => s.id.equals(storeId))
                ..limit(1)) // Bounded for memory safety (Gotcha #14)
              .getSingleOrNull();
      final storeName = store?.name ?? 'Unknown Store';

      // Submissions for this store
      final storeSubs =
          await (_db.select(_db.cachedSubmissions)
                ..where((s) => s.storeId.equals(storeId))
                ..where((s) => s.reviewStatus.equals('rejected').not())
                ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
                ..limit(1000)) // Bounded to 1000 (Gotcha #14)
              .get();

      final recentAudits = storeSubs.take(10).toList();

      final scored = storeSubs.where((s) => s.totalScore != null).toList();
      final avgScore = scored.isNotEmpty
          ? scored.map((s) => s.totalScore!).reduce((a, b) => a + b) /
                scored.length
          : 0.0;

      // Open APs for this store via submission subquery
      final openAPsQuery = _db.select(_db.cachedActionPlans)
        ..where((ap) => ap.status.equals('open'))
        ..where(
          (ap) => ap.submissionId.isInQuery(
            _db.selectOnly(_db.cachedSubmissions)
              ..addColumns([_db.cachedSubmissions.id])
              ..where(_db.cachedSubmissions.storeId.equals(storeId)),
          ),
        )
        ..limit(1000); // Bounded for memory safety (Gotcha #14)

      final openAPList = await openAPsQuery.get();

      data = StoreDashboardData(
        storeName: storeName,
        avgScore: avgScore,
        openAPs: openAPList.length,
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
