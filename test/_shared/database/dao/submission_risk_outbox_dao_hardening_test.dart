import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';

void main() {
  group('SubmissionRiskOutboxDao Hardening Tests (Slice 2)', () {
    late AppDatabase db;
    late SubmissionRiskOutboxDao dao;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = SubmissionRiskOutboxDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'TC-01: SubmissionRiskOutboxDao_updateRetry_SetsRetryCountAndNextRetryAt',
      () async {
        // Arrange
        final now = DateTime.now();
        await dao.enqueueRisk('sub-1', 'risk-1');
        
        final rowsBefore = await db.select(db.submissionRiskOutboxEntries).get();
        final id = rowsBefore.first.id;

        // Act
        // Cast to dynamic to bypass compilation error since method doesn't exist yet
        final nextRetry = now.add(const Duration(seconds: 30));
        try {
          await (dao as dynamic).updateRetry(id, 1, nextRetry, 'Network Error');
        } catch (_) {
          // Ignore NoSuchMethodError to let the assert fail
        }

        // Assert
        final rowsAfter = await db.select(db.submissionRiskOutboxEntries).get();
        expect(rowsAfter.first.retryCount, 1, reason: 'Retry count should be updated to 1');
        expect(rowsAfter.first.nextRetryAt, isNotNull, reason: 'Next retry time should be set');
        expect(rowsAfter.first.syncError, 'Network Error', reason: 'Sync error should be recorded');
      },
    );

    test(
      'TC-02: SubmissionRiskOutboxDao_markExhausted_SetsStatusExhausted',
      () async {
        // Arrange
        await dao.enqueueRisk('sub-2', 'risk-2');
        
        final rowsBefore = await db.select(db.submissionRiskOutboxEntries).get();
        final id = rowsBefore.first.id;

        // Act
        try {
          await (dao as dynamic).markExhausted(id, 'Fatal 400 Bad Request');
        } catch (_) {
          // Ignore NoSuchMethodError to let the assert fail
        }

        // Assert
        final rowsAfter = await db.select(db.submissionRiskOutboxEntries).get();
        expect(rowsAfter.first.syncStatus, 'exhausted', reason: 'Status should be marked exhausted');
        expect(rowsAfter.first.syncError, 'Fatal 400 Bad Request', reason: 'Fatal error should be recorded');
      },
    );

    test(
      'SubmissionRiskOutboxDao_getEligiblePending_ExcludesRowsWithFutureNextRetryAt',
      () async {
        // Arrange
        await dao.enqueueRisk('sub-3', 'risk-3'); // Eligible
        
        // Insert a row that is waiting for backoff
        await db.into(db.submissionRiskOutboxEntries).insert(
          SubmissionRiskOutboxEntriesCompanion.insert(
            id: 'waiting-id',
            submissionId: 'sub-4',
            globalRiskId: 'risk-4',
            syncStatus: const Value('pending'),
            nextRetryAt: Value(DateTime.now().add(const Duration(minutes: 5))), // Future
            createdAt: DateTime.now(),
          ),
        );

        // Insert a row that has backoff expired
        await db.into(db.submissionRiskOutboxEntries).insert(
          SubmissionRiskOutboxEntriesCompanion.insert(
            id: 'expired-id',
            submissionId: 'sub-5',
            globalRiskId: 'risk-5',
            syncStatus: const Value('pending'),
            nextRetryAt: Value(DateTime.now().subtract(const Duration(minutes: 1))), // Past
            createdAt: DateTime.now(),
          ),
        );

        // Act
        final pending = await dao.getEligiblePending();

        // Assert
        // We expect the first one (sub-3, no nextRetryAt) and the third one (sub-5, past nextRetryAt)
        // The second one (waiting-id) should be excluded
        expect(pending.length, 2);
        final ids = pending.map((e) => e.id).toList();
        expect(ids, contains('expired-id'));
        expect(ids, isNot(contains('waiting-id')));
      },
    );
  });
}
