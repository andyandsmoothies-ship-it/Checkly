import 'pending_submission.dart';

abstract class Outbox {
  /// All pending entries (snapshot).
  List<PendingSubmission> get pending;

  /// Add an entry to the outbox.
  Future<void> add(PendingSubmission entry);

  /// Remove an entry by its idempotency key.
  Future<void> remove(String idempotencyKey);
}
