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

  /// Get submissions eligible for sync — `pending` status AND
  /// `nextRetryAt IS NULL OR nextRetryAt <= now` (Pillar D backoff gate).
  /// Items with a future `nextRetryAt` are invisible to the SyncEngine.
  Future<List<PendingSubmission>> getEligiblePending() async {
    final now = DateTime.now().toUtc();
    return (_db.select(_db.pendingSubmissions)
          ..where(
            (s) =>
                s.syncStatus.equals('pending') &
                (s.nextRetryAt.isNull() | s.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
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

  /// Update sync status of a submission, with optional backoff fields.
  Future<void> updateSyncStatus(
    String id,
    String status, {
    String? error,
    int? retryCount,
    DateTime? nextRetryAt,
  }) async {
    await (_db.update(
      _db.pendingSubmissions,
    )..where((s) => s.id.equals(id))).write(
      PendingSubmissionsCompanion(
        syncStatus: Value(status),
        syncError: Value(error),
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
        nextRetryAt: Value(nextRetryAt), // Always write — allows nulling to null
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
  // Exhaustion Stream + Recovery
  // ============================================================

  /// Stream of the total count of exhausted records across both tables.
  /// Emits whenever the submissions table changes (combined with a point-in-time
  /// photo count). Used to drive the UX Red Badge.
  Stream<int> watchExhaustedCount() {
    return (_db.select(_db.pendingSubmissions)
          ..where((s) => s.syncStatus.equals('exhausted')))
        .watch()
        .asyncMap((subRows) async {
          final photoRows = await (_db.select(_db.pendingPhotos)
                ..where((p) => p.syncStatus.equals('exhausted')))
              .get();
          return subRows.length + photoRows.length;
        });
  }

  /// Reset all exhausted records in both tables back to `pending`.
  /// Clears `retryCount` and `nextRetryAt` — they become eligible immediately.
  Future<void> requeueExhausted() async {
    await (_db.update(_db.pendingSubmissions)
          ..where((s) => s.syncStatus.equals('exhausted')))
        .write(
          const PendingSubmissionsCompanion(
            syncStatus: Value('pending'),
            retryCount: Value(0),
            nextRetryAt: Value(null),
            syncError: Value(null),
          ),
        );

    await (_db.update(_db.pendingPhotos)
          ..where((p) => p.syncStatus.equals('exhausted')))
        .write(
          const PendingPhotosCompanion(
            syncStatus: Value('pending'),
            retryCount: Value(0),
            nextRetryAt: Value(null),
            syncError: Value(null),
          ),
        );
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

  /// Get all photos for a pending submission, ordered FIFO by createdAt.
  Future<List<PendingPhoto>> getPhotosForSubmission(String submissionId) async {
    return (_db.select(
      _db.pendingPhotos,
    )
          ..where((p) => p.pendingSubmissionId.equals(submissionId))
          ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
        .get();
  }

  /// Update sync status of a photo, with optional backoff fields.
  Future<void> updatePhotoSyncStatus(
    String id,
    String status, {
    String? error,
    int? retryCount,
    DateTime? nextRetryAt,
  }) async {
    await (_db.update(_db.pendingPhotos)..where((p) => p.id.equals(id))).write(
      PendingPhotosCompanion(
        syncStatus: Value(status),
        syncError: Value(error),
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
        nextRetryAt: Value(nextRetryAt),
      ),
    );
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
