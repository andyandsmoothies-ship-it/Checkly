// Core data structures and interfaces for offline synchronization.
//
// Extracted from sync_engine.dart for interface separation and FSD compliance.

// ============================================================
// Data Types
// ============================================================

/// Represents an offline record waiting to be synced.
class PendingSubmission {
  final String idempotencyKey;
  final DateTime createdAt;
  final String payload;

  const PendingSubmission({
    required this.idempotencyKey,
    required this.createdAt,
    required this.payload,
  });
}

/// Result of a delta pull — carries the server's latest timestamp.
class DeltaPullResult {
  final DateTime serverTimestamp;

  const DeltaPullResult({required this.serverTimestamp});
}

/// Result of a [PhotoQueueService.drainQueue] call.
/// Replaces the previous `bool` return to enable non-blocking 429 handling.
sealed class DrainResult {
  const DrainResult();
}

/// Entire batch succeeded (or queue was empty).
class DrainSuccess extends DrainResult {
  const DrainSuccess();
}

/// A 429 Retry-After response was received.
/// The caller should schedule a retry after [delay] — drainQueue did NOT block.
class DrainRetryScheduled extends DrainResult {
  final Duration delay;
  const DrainRetryScheduled(this.delay);
}

/// A retriable network error occurred. SQLite backoff was applied.
class DrainFailure extends DrainResult {
  const DrainFailure();
}

/// Represents a pending offline global risk trigger waiting to be pushed.
class PendingSubmissionRisk {
  final String submissionId;
  final String globalRiskId;

  const PendingSubmissionRisk({
    required this.submissionId,
    required this.globalRiskId,
  });
}

// ============================================================
// Interfaces
// ============================================================

/// Abstract API for sync operations.
abstract class SyncApi {
  /// Push a single pending submission to the server.
  Future<void> pushSubmission(PendingSubmission submission);

  /// Pull delta updates from server since [since].
  Future<DeltaPullResult> pullDeltas(DateTime? since);

  /// Pull global risks delta from server since [since].
  Future<List<dynamic>> pullGlobalRisks(DateTime? since);

  /// Push a pending submission risk trigger to the server.
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk);
}

/// Abstract API for media/photo uploads during Phase 2 queueing.
abstract class PhotoApi {
  /// Upload a single photo payload to the server.
  /// Returns the signed/public URL of the successfully uploaded asset.
  Future<String> uploadPhoto(String sId, String path, {String? answerId});
}

/// Abstract outbox for pending submissions.
abstract class Outbox {
  /// All pending entries (snapshot).
  List<PendingSubmission> get pending;

  /// Add an entry to the outbox.
  Future<void> add(PendingSubmission entry);

  /// Remove an entry by its idempotency key.
  Future<void> remove(String idempotencyKey);
}

/// Abstract auth check for sync gating.
abstract class AuthCheck {
  /// Whether the user is currently logged in with a valid session.
  bool get isLoggedIn;
}
