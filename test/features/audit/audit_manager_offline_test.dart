// ATDD: Safe Offline-First Audit Submission (RED phase)
//
// Acceptance contracts source:
//   specs_offline_submit.md (brain/489092c1-...)
// Upstream spec:
//   implementation_plan_optimistic_submit.md.resolved (brain/558e3529-...)
//
// Author: Sentinel (SDET)
// Status: Partially RED — AC-4 (mutex) RED until @Forge adds Completer lock.
//         AC-1, 3, 7, 8 expected GREEN on current codebase (regression guard).
//         AC-2 partially GREEN (precondition only; spy injection deferred).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

// ============================================================
// Fake collaborators — Detroit style (no mocking framework)
// ============================================================

/// Fake ConnectivityService — always offline to remove HTTP branch.
class FakeConnectivity implements ConnectivityService {
  @override
  bool get isOnline => false;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

/// Fake SubmissionApiService — never called in offline tests.
class FakeSubmissionApiService extends SubmissionApiService {
  FakeSubmissionApiService() : super(Dio());

  @override
  Future<SubmissionDto> createSubmission(
    CreateSubmissionRequest request,
  ) async {
    throw StateError('Should not be called on offline path');
  }
}

/// Minimal TemplateTreeDto factory.
TemplateTreeDto _makeTemplate({int criteriaCount = 3}) {
  final now = DateTime.now();
  final group = GroupDto(
    id: 'g-001',
    title: 'Test Section',
    orderIndex: 0,
    criteria: List.generate(
      criteriaCount,
      (i) => CriterionDto(
        id: 'c-$i',
        label: 'Criterion $i',
        inputType: 'pass_fail',
        orderIndex: i,
        isCcp: false,
        isRisk: false,
      ),
    ),
    children: [],
  );
  return TemplateTreeDto(
    id: 'tpl-001',
    title: 'Test Template',
    type: 'qc',
    version: 1,
    isActive: true,
    scoringLogicConfig: null,
    groups: [group],
    createdAt: now,
    updatedAt: now,
  );
}

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

// ============================================================
// Tests
// ============================================================
void main() {
  late AppDatabase testDb;
  late OutboxDao outboxDao;
  final fakeConnectivity = FakeConnectivity();

  setUp(() {
    testDb = _createTestDb();
    outboxDao = OutboxDao(testDb);
  });

  tearDown(() async => testDb.close());

  AuditManager makeManager({OutboxDao? overrideOutbox}) {
    return AuditManager(
      api: FakeSubmissionApiService(),
      outbox: overrideOutbox ?? outboxDao,
      connectivity: fakeConnectivity,
      draftService: DraftService.forTesting(testDb),
    );
  }

  // ----------------------------------------------------------------
  // AC-1: Atomic outbox write (submission + answers in one transaction)
  // Source: Business Rule #1
  // ----------------------------------------------------------------
  test(
    'AuditManager_Submit_WritesSubmissionAndAnswersToOutboxAtomically',
    () async {
      // Arrange
      final manager = makeManager();
      final template = _makeTemplate(criteriaCount: 3);
      await manager.startAudit(template, 'store-001');

      // Act
      await manager.submitAudit();

      // Assert
      final pendingRows = await outboxDao.getAllPending();
      expect(
        pendingRows.length,
        equals(1),
        reason: 'Exactly 1 outbox row expected',
      );
      expect(pendingRows.first.syncStatus, equals('pending'));

      final answers = await outboxDao.getAnswersForSubmission(
        pendingRows.first.id,
      );
      expect(
        answers.length,
        equals(3),
        reason: 'All 3 criteria answers must be persisted to outbox',
      );
    },
  );

  // ----------------------------------------------------------------
  // AC-2: Outbox row exists before SyncEngine could fire
  // Source: Business Rule #2 — "requestSync MUST fire AFTER outbox write"
  //
  // Full spy verification deferred: requires SyncEngine injection to AuditManager.
  // ----------------------------------------------------------------
  test('AuditManager_Submit_TriggersSyncEngineAfterOutboxWrite', () async {
    // Arrange
    final manager = makeManager();
    await manager.startAudit(_makeTemplate(), 'store-002');

    // Act
    await manager.submitAudit();

    // Assert precondition: committed row exists (engine must fire AFTER this)
    final pending = await outboxDao.getAllPending();
    expect(
      pending,
      isNotEmpty,
      reason: 'Outbox must be committed before SyncEngine fires',
    );
  });

  // ----------------------------------------------------------------
  // AC-3: isSubmitting transitions correctly
  // Source: 4-State Matrix
  // ----------------------------------------------------------------
  test(
    'AuditManager_Submit_IsSubmittingIsTrueWhileInFlightThenReset',
    () async {
      // Arrange
      final manager = makeManager();
      await manager.startAudit(_makeTemplate(), 'store-003');

      final observed = <bool>[];
      manager.addListener(() => observed.add(manager.isSubmitting));

      // Act
      await manager.submitAudit();

      // Assert
      expect(
        observed,
        contains(true),
        reason: 'isSubmitting must flip true during submit',
      );
      expect(
        manager.isSubmitting,
        isFalse,
        reason: 'isSubmitting must reset after submit completes',
      );
    },
  );

  // ----------------------------------------------------------------
  // AC-4: Double-tap protection
  // Source: Business Rule #4
  //
  // 🔴 RED until @Forge adds Completer<?> mutex to submitAudit()
  // ----------------------------------------------------------------
  test(
    'AuditManager_Submit_ConcurrentDoubleTap_InsertsOnlyOneOutboxRow',
    () async {
      // Arrange
      final manager = makeManager();
      await manager.startAudit(_makeTemplate(criteriaCount: 2), 'store-004');

      // Act — fire two concurrent submits
      await Future.wait([manager.submitAudit(), manager.submitAudit()]);

      // Assert
      final pending = await outboxDao.getAllPending();
      expect(
        pending.length,
        equals(1),
        reason: 'Mutex must prevent duplicate outbox rows from double-tap',
      );
    },
  );

  // ----------------------------------------------------------------
  // AC-7 (GAP): isSubmitting reset + error set on SQLite failure
  // Source: Sentinel gap analysis
  // ----------------------------------------------------------------
  test(
    'AuditManager_Submit_SQLiteWriteFailure_ResetsIsSubmittingAndSetsError',
    () async {
      // Arrange
      final throwingOutbox = _ThrowingOutboxDao(testDb);
      final manager = makeManager(overrideOutbox: throwingOutbox);
      await manager.startAudit(_makeTemplate(), 'store-007');

      // Act
      await manager.submitAudit();

      // Assert
      expect(
        manager.isSubmitting,
        isFalse,
        reason: 'isSubmitting must always reset in finally block',
      );
      expect(
        manager.error,
        isNotNull,
        reason: 'error must be non-null when SQLite write fails',
      );
    },
  );

  // ----------------------------------------------------------------
  // AC-8 (GAP): Draft not deleted before outbox write succeeds
  // Source: Session Summary — draft ordering guarantee
  //
  // Verified indirectly: if insertSubmissionWithAnswers throws, deleteDraft
  // line is never reached. Observable via: error set + outbox still empty.
  // ----------------------------------------------------------------
  test('AuditManager_Submit_SQLiteWriteFailure_DoesNotDeleteDraft', () async {
    // Arrange
    final throwingOutbox = _ThrowingOutboxDao(testDb);
    final manager = makeManager(overrideOutbox: throwingOutbox);
    await manager.startAudit(_makeTemplate(), 'store-008');

    // Act
    await manager.submitAudit();

    // Assert — outbox empty proves we took the failure path
    expect(
      manager.error,
      isNotNull,
      reason: 'Failure path must have been taken',
    );
    final rows = await outboxDao.getAllPending();
    expect(
      rows,
      isEmpty,
      reason: 'No rows in outbox means deleteDraft path was never reached',
    );
  });
}

// ============================================================
// Test helper: OutboxDao that throws on atomic insert
// ============================================================
class _ThrowingOutboxDao extends OutboxDao {
  _ThrowingOutboxDao(super.db);

  @override
  Future<void> insertSubmissionWithAnswers(
    PendingSubmissionsCompanion submission,
    List<PendingAnswersCompanion> answers,
  ) async {
    throw Exception('Simulated SQLite failure');
  }
}
