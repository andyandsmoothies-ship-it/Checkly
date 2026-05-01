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

  // ── Outbox: PendingProgramSubmissions ──────────────────────────────────────

  /// Enqueue a new evidence submission to dispatch when online.
  Future<void> enqueue(PendingProgramSubmissionsCompanion entry) async {
    await _db.into(_db.pendingProgramSubmissions).insert(entry);
  }

  /// Get all pending items ordered FIFO by createdAt (limit 50).
  /// Items with a future [nextRetryAt] are invisible to the SyncEngine.
  Future<List<PendingProgramSubmission>> getEligiblePending() async {
    final now = DateTime.now().toUtc();
    return (_db.select(_db.pendingProgramSubmissions)
          ..where(
            (r) =>
                r.syncStatus.equals('pending') &
                (r.nextRetryAt.isNull() | r.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)])
          ..limit(50))
        .get();
  }

  /// Remove a submitted row after a successful server response.
  Future<void> remove(String id) async {
    await (_db.delete(_db.pendingProgramSubmissions)
          ..where((r) => r.id.equals(id)))
        .go();
  }

  /// Mark a row as permanently failed (max retries exhausted or 400/403).
  Future<void> markExhausted(String id, String error) async {
    await (_db.update(_db.pendingProgramSubmissions)
          ..where((r) => r.id.equals(id)))
        .write(
      PendingProgramSubmissionsCompanion(
        syncStatus: const Value('exhausted'),
        syncError: Value(error),
      ),
    );
  }

  /// Update retry state with backoff delay on transient network failure.
  Future<void> updateRetry(
    String id,
    int newCount,
    DateTime nextRetry,
    String error,
  ) async {
    await (_db.update(_db.pendingProgramSubmissions)
          ..where((r) => r.id.equals(id)))
        .write(
      PendingProgramSubmissionsCompanion(
        retryCount: Value(newCount),
        nextRetryAt: Value(nextRetry),
        syncError: Value(error),
      ),
    );
  }

  // ── Cache: CachedProgramAssignments ───────────────────────────────────────

  /// Insert or replace a single cached assignment row (upsert).
  Future<void> upsertCachedAssignment(
    CachedProgramAssignmentsCompanion row,
  ) async {
    await _db
        .into(_db.cachedProgramAssignments)
        .insertOnConflictUpdate(row);
  }

  /// Delete ALL cached assignments (full-replace pull strategy).
  Future<void> deleteAllCachedAssignments() async {
    await _db.delete(_db.cachedProgramAssignments).go();
  }

  /// Watch cached assignments as a live stream (for home widget in Slice C).
  Stream<List<CachedProgramAssignment>> watchPendingAssignments() {
    return (_db.select(_db.cachedProgramAssignments)
          ..where((r) => r.status.equals('pending') | r.status.equals('overdue'))
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
    return (_db.select(_db.cachedProgramAssignments)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  // ── Outbox: PendingProgramPhotos ──────────────────────────────────────────

  /// Enqueue a photo to upload when online.
  Future<void> enqueuePhoto(PendingProgramPhotosCompanion entry) async {
    await _db.into(_db.pendingProgramPhotos).insert(entry);
  }

  /// Get all pending photos ordered FIFO by createdAt.
  ///
  /// Used by [SyncEngine._drainProgramPhotos].
  Future<List<PendingProgramPhoto>> getPendingPhotos() {
    return (_db.select(_db.pendingProgramPhotos)
          ..where((r) => r.syncStatus.equals('pending'))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)])
          ..limit(50))
        .get();
  }

  /// Remove a photo after successful upload.
  Future<void> removePhoto(String id) async {
    await (_db.delete(_db.pendingProgramPhotos)
          ..where((r) => r.id.equals(id)))
        .go();
  }
  /// Mark a photo row as permanently failed (max retries exhausted or 400/403/415).
  Future<void> markPhotoExhausted(String id, String error) async {
    await (_db.update(_db.pendingProgramPhotos)
          ..where((r) => r.id.equals(id)))
        .write(
      PendingProgramPhotosCompanion(
        syncStatus: const Value('exhausted'),
        syncError: Value(error),
      ),
    );
  }

  /// Update photo retry state with backoff delay on transient network failure.
  Future<void> updatePhotoRetry(
    String id,
    int newCount,
    DateTime nextRetry,
    String error,
  ) async {
    await (_db.update(_db.pendingProgramPhotos)
          ..where((r) => r.id.equals(id)))
        .write(
      PendingProgramPhotosCompanion(
        retryCount: Value(newCount),
        nextRetryAt: Value(nextRetry),
        syncError: Value(error),
      ),
    );
  }
}

