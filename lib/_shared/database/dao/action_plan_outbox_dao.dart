import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO for the action plan outbox — pending evidence submissions queued offline.
class ActionPlanOutboxDao {
  final AppDatabase _db;

  ActionPlanOutboxDao(this._db);

  /// Enqueue a new evidence submission to dispatch when online.
  Future<void> enqueue(PendingActionPlanUpdatesCompanion entry) async {
    await _db.into(_db.pendingActionPlanUpdates).insert(entry);
  }

  /// Get all pending items ordered FIFO by createdAt.
  Future<List<PendingActionPlanUpdate>> getEligiblePending() async {
    return (_db.select(_db.pendingActionPlanUpdates)
          ..where((r) => r.syncStatus.equals('pending'))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)])
          ..limit(50))
        .get();
  }

  /// Mark a queued item as successfully synced and remove it.
  Future<void> remove(String id) async {
    await (_db.delete(
      _db.pendingActionPlanUpdates,
    )..where((r) => r.id.equals(id))).go();
  }

  /// Mark an item with an error status after exhausting retries.
  Future<void> markExhausted(String id, String error) async {
    await (_db.update(
      _db.pendingActionPlanUpdates,
    )..where((r) => r.id.equals(id))).write(
      PendingActionPlanUpdatesCompanion(
        syncStatus: const Value('exhausted'),
        syncError: Value(error),
      ),
    );
  }

  /// Count of pending (not yet attempted) items — for debug/badge use.
  Future<int> pendingCount() async {
    final countExp = countAll();
    final query = _db.selectOnly(_db.pendingActionPlanUpdates)
      ..addColumns([countExp])
      ..where(_db.pendingActionPlanUpdates.syncStatus.equals('pending'));
    return await query.map((row) => row.read(countExp)).getSingle() ?? 0;
  }

  /// Mark an item as rejected due to a stale offline state.
  Future<void> markStaleConflict(String id) async {
    await (_db.update(
      _db.pendingActionPlanUpdates,
    )..where((r) => r.id.equals(id))).write(
      const PendingActionPlanUpdatesCompanion(
        syncStatus: Value('stale_conflict'),
      ),
    );
  }

  /// Get the stale conflict for a specific action plan, if it exists.
  Future<PendingActionPlanUpdate?> getStaleConflictForPlan(String planId) async {
    return (_db.select(_db.pendingActionPlanUpdates)
          ..where((r) => r.actionPlanId.equals(planId) & r.syncStatus.equals('stale_conflict'))
          ..limit(1))
        .getSingleOrNull();
  }
}
