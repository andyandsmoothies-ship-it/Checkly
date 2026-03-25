import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for the transactional outbox — pending submissions, answers, and photos.
class OutboxDao {
  final AppDatabase _db;

  OutboxDao(this._db);

  // ============================================================
  // Pending Submissions
  // ============================================================

  /// Get all pending submissions ordered by createdAt (FIFO).
  Future<List<PendingSubmission>> getAllPending() async {
    return (_db.select(_db.pendingSubmissions)
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)])
          ..limit(100)) // Bounded to 100 per sync batch (Gotcha #14)
        .get();
  }

  /// Get pending submissions by sync status.
  Future<List<PendingSubmission>> getPendingByStatus(String status) async {
    return (_db.select(_db.pendingSubmissions)
          ..where((s) => s.syncStatus.equals(status))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
  }

  /// Insert a new pending submission.
  Future<void> insertSubmission(PendingSubmissionsCompanion entry) async {
    await _db.into(_db.pendingSubmissions).insert(entry);
  }

  /// Update sync status of a submission.
  Future<void> updateSyncStatus(
    String id,
    String status, {
    String? error,
  }) async {
    await (_db.update(
      _db.pendingSubmissions,
    )..where((s) => s.id.equals(id))).write(
      PendingSubmissionsCompanion(
        syncStatus: Value(status),
        syncError: Value(error),
      ),
    );
  }

  /// Remove a fully synced submission and its answers + photos.
  Future<void> removeSubmission(String id) async {
    await (_db.delete(
      _db.pendingAnswers,
    )..where((a) => a.pendingSubmissionId.equals(id))).go();
    await (_db.delete(
      _db.pendingPhotos,
    )..where((p) => p.pendingSubmissionId.equals(id))).go();
    await (_db.delete(
      _db.pendingSubmissions,
    )..where((s) => s.id.equals(id))).go();
  }

  /// Remove a submission by its idempotency key (used by SyncEngine).
  Future<void> removeByIdempotencyKey(String key) async {
    final row = await (_db.select(
      _db.pendingSubmissions,
    )..where((s) => s.idempotencyKey.equals(key))).getSingleOrNull();
    if (row != null) {
      await removeSubmission(row.id);
    }
  }

  // ============================================================
  // Pending Answers
  // ============================================================

  /// Insert a batch of answers for a pending submission.
  Future<void> insertAnswers(List<PendingAnswersCompanion> answers) async {
    await _db.batch((b) {
      b.insertAll(_db.pendingAnswers, answers);
    });
  }

  /// Get all answers for a pending submission.
  Future<List<PendingAnswer>> getAnswersForSubmission(
    String submissionId,
  ) async {
    return (_db.select(
      _db.pendingAnswers,
    )..where((a) => a.pendingSubmissionId.equals(submissionId))).get();
  }

  // ============================================================
  // Pending Photos
  // ============================================================

  /// Insert a pending photo.
  Future<void> insertPhoto(PendingPhotosCompanion photo) async {
    await _db.into(_db.pendingPhotos).insert(photo);
  }

  /// Get all photos for a pending submission.
  Future<List<PendingPhoto>> getPhotosForSubmission(String submissionId) async {
    return (_db.select(
      _db.pendingPhotos,
    )..where((p) => p.pendingSubmissionId.equals(submissionId))).get();
  }

  // ============================================================
  // Counts
  // ============================================================

  /// Count of pending submissions (for badge/indicator).
  Future<int> pendingCount() async {
    final rows = await _db.select(_db.pendingSubmissions).get();
    return rows.length;
  }
}
