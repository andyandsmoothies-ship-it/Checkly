import 'dart:io';
import 'dart:math';

import '../database/dao/outbox_dao.dart';
import 'drain_result.dart';
import 'photo_api.dart';
import 'package:dio/dio.dart';

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
  final PhotoApi _api;
  final List<int> _backoffDelays;

  /// Injectable file-existence check — defaults to `File(path).existsSync()`.
  /// Exposed for testing without touching the real filesystem.
  final bool Function(String path) fileExists;

  /// Injectable [Random] instance — allows seeding in tests to produce deterministic jitter.
  final Random _random;

  PhotoQueueService(
    this._outbox,
    this._api, {
    bool Function(String)? fileExists,
    List<int> backoffDelays = _defaultBackoffDelays,
    Random? random,
  }) : fileExists = fileExists ?? ((path) => File(path).existsSync()),
       _backoffDelays = backoffDelays,
       _random = random ?? Random();

  /// Uploads all pending photos for [submissionId] in FIFO order.
  Future<DrainResult> drainQueue(String submissionId) async {
    final photos = await _outbox.getPhotosForSubmission(submissionId);

    // Filter to only 'pending' photos — skip already uploaded/errored/exhausted.
    final pending = photos.where((p) => p.syncStatus == 'pending').toList();

    if (pending.isEmpty) return const DrainSuccess();

    // Rule 1.1 & 1.2: Jitter delay occurs ONCE before the loop — NOT per-photo.
    // Breaks up synchronized reconnect stampedes (e.g. 10 auditors returning to office Wi-Fi).
    final jitterSecs = _random.nextInt(16); // 0 to 15 inclusive
    if (jitterSecs > 0) {
      await Future<void>.delayed(Duration(seconds: jitterSecs));
    }

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
      } on Exception catch (e) {
        // Rule 1.3: If server returned 429 with Retry-After header (ConcurrencyLimiter overload),
        // respect the server's wait time instead of writing a backoff entry to SQLite.
        // The SyncEngine will re-trigger drainQueue after the connection recovers.
        final retryAfterSecs = _extractRetryAfter(e);
        if (retryAfterSecs != null) {
          return DrainRetryScheduled(Duration(seconds: retryAfterSecs));
        }

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
        return const DrainFailure();
      }
    }

    return const DrainSuccess();
  }

  /// Extracts the [Retry-After] seconds value from a [DioException] response header.
  /// Returns null if the error is not a 429 or the header is absent/unparseable.
  int? _extractRetryAfter(Exception e) {
    if (e is DioException) {
      if (e.response?.statusCode == 429) {
        final raw = e.response?.headers.value('retry-after');
        if (raw != null) {
          return int.tryParse(raw);
        }
      }
    }
    return null;
  }
}
