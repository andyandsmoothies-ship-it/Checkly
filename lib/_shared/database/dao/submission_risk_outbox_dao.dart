import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for the submission_risk_outbox_entries table.
/// Queues offline global risk triggers to be pushed when connectivity is restored.
class SubmissionRiskOutboxDao {
  final AppDatabase _db;

  SubmissionRiskOutboxDao(this._db);

  /// Add a pending risk trigger to the outbox.
  Future<void> enqueueRisk(String submissionId, String globalRiskId) async {
    await _db
        .into(_db.submissionRiskOutboxEntries)
        .insert(
          SubmissionRiskOutboxEntriesCompanion.insert(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            submissionId: submissionId,
            globalRiskId: globalRiskId,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Get pending (not yet pushed) risk triggers, FIFO ordered.
  /// OOM Guard: Batched to 50 records per sync cycle. If the offline backlog
  /// exceeds 50, the remainder drains on the next connectivity pulse.
  Future<List<SubmissionRiskOutboxEntry>> getEligiblePending() async {
    return (_db.select(_db.submissionRiskOutboxEntries)
          ..where((r) => r.syncStatus.equals('pending'))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)])
          ..limit(50))
        .get();
  }

  /// Remove a successfully pushed risk trigger from the outbox.
  Future<void> remove(String id) async {
    await (_db.delete(
      _db.submissionRiskOutboxEntries,
    )..where((r) => r.id.equals(id))).go();
  }

  /// Remove a risk trigger by submissionId and globalRiskId.
  /// Used when an auditor un-triggers a risk before final submission.
  Future<void> removeByRiskId(String submissionId, String globalRiskId) async {
    await (_db.delete(_db.submissionRiskOutboxEntries)..where(
          (r) =>
              r.submissionId.equals(submissionId) &
              r.globalRiskId.equals(globalRiskId),
        ))
        .go();
  }

  /// Returns true if the given submission has any pending (not yet synced) risk triggers.
  /// Used by SyncEngine to set hasGlobalRisk=true in the POST /submissions payload.
  Future<bool> hasPendingRisks(String submissionId) async {
    final count =
        await (_db.selectOnly(_db.submissionRiskOutboxEntries)
              ..addColumns([_db.submissionRiskOutboxEntries.id.count()])
              ..where(
                _db.submissionRiskOutboxEntries.submissionId.equals(
                      submissionId,
                    ) &
                    _db.submissionRiskOutboxEntries.syncStatus.equals(
                      'pending',
                    ),
              ))
            .getSingle();
    return (count.read(_db.submissionRiskOutboxEntries.id.count()) ?? 0) > 0;
  }
}
