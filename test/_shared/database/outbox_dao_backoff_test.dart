// Test Contract: Pillar D — OutboxDao Backoff Tests
// AC1, AC2, AC3, AC7, AC8, AC10
// Author: Sentinel (SDET) / Executed: Builder (Forge)

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

import 'package:checkly/_shared/database/app_database.dart'
    hide PendingSubmission;
import 'package:checkly/_shared/database/dao/outbox_dao.dart';

void main() {
  late AppDatabase db;
  late OutboxDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OutboxDao(db);
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

  Future<void> insertSub(
    String id, {
    String status = 'pending',
    int retryCount = 0,
    DateTime? nextRetryAt,
  }) async {
    await dao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        templateId: 't1',
        storeId: 's1',
        clientScore: 100.0,
        idempotencyKey: id,
        syncStatus: Value(status),
        retryCount: Value(retryCount),
        nextRetryAt: Value(nextRetryAt),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  // ---------------------------------------------------------------
  // AC1: Default schema state
  // ---------------------------------------------------------------
  test('AC1: OutboxDao_NewSubmission_HasDefaultBackoffState', () async {
    await insertSub('sub-1');

    final rows = await db.select(db.pendingSubmissions).get();
    expect(rows.length, 1);
    expect(rows.first.retryCount, 0);
    expect(rows.first.nextRetryAt, isNull);
    expect(rows.first.syncStatus, 'pending');
  });

  // ---------------------------------------------------------------
  // AC2: Future nextRetryAt is invisible to getEligiblePending
  // ---------------------------------------------------------------
  test('AC2: OutboxDao_GetEligiblePending_ExcludesFutureRetry', () async {
    final future = DateTime.now().toUtc().add(const Duration(hours: 1));
    await insertSub('sub-a', nextRetryAt: future); // future — should be hidden
    await insertSub('sub-b'); // null nextRetryAt — should be visible

    final eligible = await dao.getEligiblePending();
    final ids = eligible.map((r) => r.id).toList();

    expect(ids, contains('sub-b'));
    expect(ids, isNot(contains('sub-a')));
  });

  // ---------------------------------------------------------------
  // AC3: Past-due nextRetryAt is eligible
  // ---------------------------------------------------------------
  test('AC3: OutboxDao_GetEligiblePending_IncludesPastRetry', () async {
    final past = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    await insertSub('sub-1', nextRetryAt: past);

    final eligible = await dao.getEligiblePending();
    expect(eligible.map((r) => r.id), contains('sub-1'));
  });

  // ---------------------------------------------------------------
  // AC7: watchExhaustedCount emits correct sum
  // ---------------------------------------------------------------
  test('AC7: OutboxDao_WatchExhaustedCount_EmitsPositiveSum', () async {
    await insertSub('sub-exhausted', status: 'exhausted');

    // Insert an exhausted photo
    await db
        .into(db.pendingPhotos)
        .insert(
          PendingPhotosCompanion.insert(
            id: 'photo-exhausted',
            pendingSubmissionId: 'sub-exhausted',
            localPath: '/tmp/x.jpg',
            createdAt: DateTime.now().toUtc(),
            syncStatus: const Value('exhausted'),
          ),
        );

    final count = await dao.watchExhaustedCount().first;
    expect(count, 2); // 1 submission + 1 photo
  });

  // ---------------------------------------------------------------
  // AC8: requeueExhausted resets all rows
  // ---------------------------------------------------------------
  test('AC8: OutboxDao_RequeueExhausted_ResetsAllRows', () async {
    await insertSub('sub-1', status: 'exhausted', retryCount: 4);
    await insertSub('sub-2', status: 'exhausted', retryCount: 4);

    await dao.requeueExhausted();

    final rows = await db.select(db.pendingSubmissions).get();
    for (final row in rows) {
      expect(row.syncStatus, 'pending');
      expect(row.retryCount, 0);
      expect(row.nextRetryAt, isNull);
    }
  });

  // ---------------------------------------------------------------
  // AC10: requeueExhausted on empty set is a safe no-op
  // ---------------------------------------------------------------
  test('AC10: OutboxDao_RequeueExhausted_EmptySet_IsNoOp', () async {
    // No exhausted rows
    await expectLater(dao.requeueExhausted(), completes);

    final count = await dao.watchExhaustedCount().first;
    expect(count, 0);
  });
}
