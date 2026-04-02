import 'dart:io';

import '../database/dao/outbox_dao.dart';
import '../../features/audit/services/submission_api_service.dart';

/// Backoff delay sequence in seconds: 1st, 2nd, 3rd, 4th failure.
const List<int> _defaultBackoffDelays = [2, 4, 8, 60];

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
///   and **continues** the batch (deterministic — no retry value, AC9).
/// - Network error: applies SQLite-persisted exponential backoff.
///   After 4 failures, status → `exhausted`. Returns `false`.
class PhotoQueueService {
  final OutboxDao _outbox;
  final SubmissionApiService _api;
  final List<int> _backoffDelays;

  /// Injectable file-existence check — defaults to `File(path).existsSync()`.
  /// Exposed for testing without touching the real filesystem.
  final bool Function(String path) fileExists;

  PhotoQueueService(
    this._outbox,
    this._api, {
    bool Function(String)? fileExists,
    List<int> backoffDelays = _defaultBackoffDelays,
  }) : fileExists = fileExists ?? ((path) => File(path).existsSync()),
       _backoffDelays = backoffDelays;

  /// Uploads all pending photos for [submissionId] in FIFO order.
  Future<bool> drainQueue(String submissionId) async {
    final photos = await _outbox.getPhotosForSubmission(submissionId);

    // Filter to only 'pending' photos — skip already uploaded/errored/exhausted.
    final pending = photos.where((p) => p.syncStatus == 'pending').toList();

    if (pending.isEmpty) return true;

    for (final photo in pending) {
      // ── Deterministic failure: missing local file ──
      // Rule 3: Missing files are FATAL — bypass backoff entirely.
      if (!fileExists(photo.localPath)) {
        await _outbox.updatePhotoSyncStatus(
          photo.id,
          'error',
          error: 'local_file_missing',
          // CRITICAL: retryCount NOT incremented — this is deterministic, not retriable.
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
        // Apply SQLite-backed exponential backoff (Pillar D).
        final currentRetries = photo.retryCount;
        if (currentRetries < _backoffDelays.length) {
          final delaySecs = _backoffDelays[currentRetries];
          final nextRetry = DateTime.now().toUtc().add(
            Duration(seconds: delaySecs),
          );
          await _outbox.updatePhotoSyncStatus(
            photo.id,
            'pending',
            retryCount: currentRetries + 1,
            nextRetryAt: nextRetry,
            error: e.toString(),
          );
        } else {
          await _outbox.updatePhotoSyncStatus(
            photo.id,
            'exhausted',
            error: 'Max retries exceeded',
          );
        }
        // BLOCK — network failure is retriable; pause remaining batch.
        return false;
      }
    }

    return true;
  }
}
