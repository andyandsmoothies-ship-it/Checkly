import 'package:drift/drift.dart';
import '../app_database.dart';

/// DAO for the sync_meta table.
/// Tracks the last successful sync timestamp for delta queries.
class SyncMetaDao {
  final AppDatabase _db;

  SyncMetaDao(this._db);

  /// Get the last sync timestamp for a specific entity type (e.g., 'global').
  Future<DateTime?> get(String entityType) async {
    final meta = await (_db.select(_db.syncMeta)
          ..where((t) => t.entityType.equals(entityType)))
        .getSingleOrNull();
    return meta?.lastSyncAt;
  }

  /// Update the last sync timestamp for an entity type.
  Future<void> set(String entityType, DateTime lastSyncAt) async {
    await _db.into(_db.syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion(
        entityType: Value(entityType),
        lastSyncAt: Value(lastSyncAt),
      ),
    );
  }
}
