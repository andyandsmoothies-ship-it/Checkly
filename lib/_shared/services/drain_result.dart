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
