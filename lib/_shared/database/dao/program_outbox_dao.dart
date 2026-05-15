import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for the Programs Module offline cache and evidence outbox.
///
/// Handles:
/// - [CachedProgramAssignments] — full-replace pull cache (SM's assignments).
/// - [PendingProgramSubmissions] — outbox for offline evidence submissions.
class ProgramOutboxDao {
  final AppDatabase _db;

  ProgramOutboxDao(this._db);

  // ── Cache: CachedProgramAssignments ───────────────────────────────────────

  /// Insert or replace a single cached assignment row (upsert).
  Future<void> upsertCachedAssignment(
    CachedProgramAssignmentsCompanion row,
  ) async {
    await _db.into(_db.cachedProgramAssignments).insertOnConflictUpdate(row);
  }

  /// Delete ALL cached assignments (full-replace pull strategy).
  Future<void> deleteAllCachedAssignments() async {
    await _db.delete(_db.cachedProgramAssignments).go();
  }

  /// Watch cached assignments as a live stream (for home widget in Slice C).
  Stream<List<CachedProgramAssignment>> watchPendingAssignments() {
    return (_db.select(_db.cachedProgramAssignments)
          ..where(
            (r) => r.status.equals('pending') | r.status.equals('overdue'),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.deadline)]))
        .watch();
  }

  /// Get all non-submitted assignments ordered by deadline ASC.
  ///
  /// Used by [ProgramManager.loadAssignments] for the assignment list.
  Future<List<CachedProgramAssignment>> getNonSubmittedAssignments() {
    return (_db.select(_db.cachedProgramAssignments)
          ..where((r) => r.status.isNotIn(['submitted']))
          ..orderBy([(r) => OrderingTerm.asc(r.deadline)])
          ..limit(50))
        .get();
  }

  /// Fetch a single cached assignment by ID.
  ///
  /// Returns `null` if not found.
  Future<CachedProgramAssignment?> getCachedAssignment(String id) {
    return (_db.select(
      _db.cachedProgramAssignments,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  // ── Store lookup ──────────────────────────────────────────────────────────

  /// Returns the ID of the SM's primary store from the local cache.
  ///
  /// A Store Manager is always assigned to exactly one store, so the first
  /// row is sufficient. Returns an empty string when the cache is empty.
  Future<String> getPrimaryStoreId() async {
    final rows = await (_db.select(_db.cachedStores)..limit(1)).get();
    return rows.isNotEmpty ? rows.first.id : '';
  }
}
