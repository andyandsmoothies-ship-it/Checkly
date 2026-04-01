import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:checkly/_shared/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('SQLite cascade trigger closes action plans when audit is voided', () async {
    // 1. Arrange: Insert a submission
    await db.into(db.cachedSubmissions).insert(CachedSubmissionsCompanion.insert(
      id: 'sub-void-1',
      status: 'completed',
      createdAt: DateTime.now(),
    ));

    // Insert an open action plan bound to the submission
    await db.into(db.cachedActionPlans).insert(CachedActionPlansCompanion.insert(
      id: 'ap-1',
      submissionId: const Value('sub-void-1'),
      criteriaLabel: 'Criteria 1',
      groupTitle: 'Group 1',
      status: const Value('open'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 2. Act: Update submission status to voided
    await db.update(db.cachedSubmissions).replace(CachedSubmissionsCompanion.insert(
      id: 'sub-void-1',
      status: 'voided', // This should trigger the AFTER UPDATE cascade
      createdAt: DateTime.now(),
    ));

    // 3. Assert: SQLite trigger implicitly closed the action plan natively
    final actionPlan = await (db.select(db.cachedActionPlans)
          ..where((t) => t.id.equals('ap-1')))
        .getSingle();

    expect(actionPlan.status, 'closed', reason: 'Cascade trigger failed to close the action plan.');
    
    // Check root_cause
    expect(actionPlan.rootCause, 'SYSTEM_VOID', reason: 'Cascade trigger failed to update root_cause.');
  });
  test('SQLite cascade trigger closes action plans on AFTER INSERT', () async {
    // 1. Arrange: Insert an open action plan bound to a submission that doesn't exist locally yet
    // (This simulates an orphan or an out-of-order sync, but primarily tests the INSERT trigger boundary).
    // Note: SQLite FKs are typically deferred or ignored unless explicitly turned on. 
    // If FK constraints are strictly enforced, this test structure might fail setup, 
    // but we are validating the trigger logic upon Submission INSERT.
    await db.into(db.cachedActionPlans).insert(CachedActionPlansCompanion.insert(
      id: 'ap-insert-2',
      submissionId: const Value('sub-void-2'),
      criteriaLabel: 'Criteria 2',
      groupTitle: 'Group 2',
      status: const Value('open'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 2. Act: Insert a NEW submission with status voided (Simulating Sync Delta Insert/Replace)
    await db.into(db.cachedSubmissions).insert(CachedSubmissionsCompanion.insert(
      id: 'sub-void-2',
      status: 'voided', // This should trigger the AFTER INSERT cascade
      createdAt: DateTime.now(),
    ), mode: InsertMode.insertOrReplace);

    // 3. Assert: SQLite trigger implicitly closed the action plan natively
    final actionPlan = await (db.select(db.cachedActionPlans)
          ..where((t) => t.id.equals('ap-insert-2')))
        .getSingle();

    expect(actionPlan.status, 'closed', reason: 'AFTER INSERT trigger failed to close the action plan.');
    
    // Check root_cause
    expect(actionPlan.rootCause, 'SYSTEM_VOID', reason: 'AFTER INSERT trigger failed to update root_cause.');
  });
}
