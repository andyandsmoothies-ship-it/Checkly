import 'dart:io';

import '../database/dao/outbox_dao.dart';
import '../../features/audit/services/submission_api_service.dart';

/// Drains the `PendingPhotos` queue for a given submission after Phase 1
/// (data sync) is confirmed complete.
///
/// Upload order is strictly FIFO (`ORDER BY created_at ASC`).
///
/// **Return contract:**
/// - Returns `true`  → entire batch succeeded (or was empty).
/// - Returns `false` → a retriable network failure occurred; batch is paused.
///
/// **Failure modes:**
/// - Missing local file: marks the photo `error` with `local_file_missing`
///   and **continues** the batch (deterministic — no retry value).
/// - Network error (`DioException`): marks the photo `error` and returns
///   `false` to signal the caller to pause and retry later.
class PhotoQueueService {
  final OutboxDao _outbox;
  final SubmissionApiService _api;

  /// Injectable file-existence check — defaults to `File(path).existsSync()`.
  /// Exposed for testing without touching the real filesystem.
  final bool Function(String path) fileExists;

  PhotoQueueService(
    this._outbox,
    this._api, {
    bool Function(String)? fileExists,
  }) : fileExists = fileExists ?? ((path) => File(path).existsSync());

  /// Uploads all pending photos for [submissionId] in FIFO order.
  Future<bool> drainQueue(String submissionId) async {
    final photos = await _outbox.getPhotosForSubmission(submissionId);

    // Filter to only 'pending' photos — skip already uploaded/errored ones.
    final pending =
        photos.where((p) => p.syncStatus == 'pending').toList();

    if (pending.isEmpty) return true;

    for (final photo in pending) {
      // ── Deterministic failure: missing local file ──
      if (!fileExists(photo.localPath)) {
        await _outbox.updatePhotoSyncStatus(
          photo.id,
          'error',
          error: 'local_file_missing',
        );
        // CONTINUE — a missing temp file is unrecoverable, do not block others.
        continue;
      }

      // ── Retriable failure: network crash ──
      try {
        await _api.uploadPhoto(
          submissionId,
          photo.localPath,
          answerId: photo.answerId,
        );
        await _outbox.updatePhotoSyncStatus(photo.id, 'uploaded');
      } catch (e) {
        await _outbox.updatePhotoSyncStatus(
          photo.id,
          'error',
          error: e.toString(),
        );
        // BLOCK — network failure is retriable; pause remaining batch.
        return false;
      }
    }

    return true;
  }
}
