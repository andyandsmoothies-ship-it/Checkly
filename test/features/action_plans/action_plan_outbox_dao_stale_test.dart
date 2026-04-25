import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';

void main() {
  group('ActionPlanOutboxDao Stale Conflict Tests (Slice 3)', () {
    late AppDatabase db;
    late ActionPlanOutboxDao dao;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = ActionPlanOutboxDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('FL-DAO-SC-01: ActionPlanOutboxDao_markStaleConflict_UpdatesSyncStatusToStaleConflict', () async {
      // Arrange
      await dao.enqueue(
        PendingActionPlanUpdatesCompanion.insert(
          id: 'test-id',
          actionPlanId: 'plan-1',
          correctionPlan: 'Fix it',
          evidenceNote: '',
          createdAt: DateTime.now(),
        ),
      );

      // Act
      // NOTE: markStaleConflict() does not exist yet. This will fail to compile
      // unless we cast or dynamically call, or we just let it fail compilation.
      // We will write the test so it fails during execution (NoSuchMethodError).
      try {
        (dao as dynamic).markStaleConflict('test-id');
      } catch (_) {
        // Ignored for compilation safety, but the test will fail on the assert below
      }

      // Assert
      final rows = await db.select(db.pendingActionPlanUpdates).get();
      expect(rows, isNotEmpty);
      expect(rows.first.syncStatus, 'stale_conflict');
    });

    test('FL-DAO-SC-02: ActionPlanOutboxDao_getStaleConflictForPlan_ReturnsRowWhenStatusIsStaleConflict', () async {
      // Arrange
      await db.into(db.pendingActionPlanUpdates).insert(
        PendingActionPlanUpdatesCompanion.insert(
          id: 'test-id-1',
          actionPlanId: 'plan-1',
          correctionPlan: 'Fix 1',
          evidenceNote: 'Note 1',
          syncStatus: const Value('stale_conflict'),
          createdAt: DateTime.now(),
        ),
      );

      // Act
      dynamic result;
      try {
        result = await (dao as dynamic).getStaleConflictForPlan('plan-1');
      } catch (_) {
        // Let it fail the expect
      }

      // Assert
      expect(result, isNotNull);
      expect(result.id, 'test-id-1');
      expect(result.syncStatus, 'stale_conflict');
    });

    test('FL-DAO-SC-03: ActionPlanOutboxDao_getStaleConflictForPlan_ReturnsNullWhenNoPendingRow', () async {
      // Act
      dynamic result;
      try {
        result = await (dao as dynamic).getStaleConflictForPlan('non-existent');
      } catch (_) {
        // Let it fail the expect
      }

      // Assert
      expect(result, isNull);
    });
  });
}
