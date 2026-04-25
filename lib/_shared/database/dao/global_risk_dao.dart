import '../app_database.dart';

/// DAO for the cached_global_risks table.
/// Stores global risks pulled from the server via delta sync.
class GlobalRiskDao {
  final AppDatabase _db;

  GlobalRiskDao(this._db);

  /// Upsert a risk from the server (insert or replace on conflict).
  Future<void> upsertRisk(CachedGlobalRisksCompanion entry) async {
    await _db.into(_db.cachedGlobalRisks).insertOnConflictUpdate(entry);
  }

  /// Get all cached risks (active and inactive).
  /// Safety: Bounded by enterprise configuration — global risks are
  /// admin-managed entities. Expected to be < 100 items system-wide.
  Future<List<CachedGlobalRisk>> getAllRisks() async {
    return _db.select(_db.cachedGlobalRisks).get();
  }

  /// Get only active risks for display in the auditor UI.
  /// Safety: Bounded by enterprise configuration — same as getAllRisks().
  Future<List<CachedGlobalRisk>> getActiveRisks() async {
    return (_db.select(
      _db.cachedGlobalRisks,
    )..where((r) => r.isActive.equals(true))).get();
  }
}
