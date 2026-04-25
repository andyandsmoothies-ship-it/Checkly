import '../app_database.dart';
import '../tables.dart';

/// DAO for the [CachedPolicies] table.
///
/// Provides full-replace upsert (login) and read (tryAutoLogin) of capability strings.
/// All writes are wrapped in a transaction — guarantees the table is never seen
/// in a half-replaced state by concurrent reads.
class PolicyDao {
  final AppDatabase _db;

  PolicyDao(this._db);

  /// Replaces all capabilities with [capabilities].
  /// Called once per active login after a successful `PolicyApiService.fetchCapabilities()`.
  ///
  /// Strategy: DELETE all → batch INSERT new.
  /// Transactional — the table is never empty mid-swap from outside.
  Future<void> upsertCapabilities(List<String> capabilities) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedPolicies).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedPolicies,
          capabilities.map(
            (c) => CachedPoliciesCompanion.insert(capability: c),
          ),
        );
      });
    });
  }

  /// Returns all stored capability strings as a [Set].
  /// Returns an empty set if the table is empty (first install or after logout).
  Future<Set<String>> getCapabilities() async {
    final rows = await _db.select(_db.cachedPolicies).get();
    return rows.map((r) => r.capability).toSet();
  }

  /// Clears all capability rows. Called on logout.
  Future<void> clearCapabilities() async {
    await _db.delete(_db.cachedPolicies).go();
  }
}
