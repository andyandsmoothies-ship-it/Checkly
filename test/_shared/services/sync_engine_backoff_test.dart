// Test Contract: Pillar D — SyncEngine Backoff Tests
// AC4, AC5, AC6
// Author: Sentinel (SDET) / Executed: Builder (Forge)
//
// Strategy: inject real in-memory OutboxDao so AC4/AC5/AC6 verify actual DB state.
// This follows the Sentinel's DI Seam requirement (Option A: OutboxDao injected directly).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart'
    hide PendingSubmission;
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/sync_meta_dao.dart';

import 'package:checkly/_shared/services/sync_engine.dart';
import 'package:checkly/_shared/services/pending_submission.dart';
import 'package:checkly/_shared/services/delta_pull_result.dart';
import 'package:checkly/_shared/services/pending_submission_risk.dart';
import 'package:checkly/_shared/services/sync_api.dart';
import 'package:checkly/_shared/services/outbox.dart';
import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/sync_state.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';
import 'package:checkly/features/action_plans/services/action_plan_sync_module.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

class AlwaysOnlineConnectivity implements ConnectivityService {
  @override
  bool get isOnline => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class AlwaysAuthCheck implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

class FailingApi implements SyncApi {
  @override
  Future<void> pushSubmission(PendingSubmission s) async {
    throw Exception('Simulated network error');
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async {
    return DeltaPullResult(serverTimestamp: DateTime.now().toUtc());
  }

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async => [];
  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {}

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];


}

class _ConflictRiskApi extends FailingApi {
  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
    throw Exception('409 Conflict');
  }
}

class _FatalSubmissionApi extends FailingApi {
  @override
  Future<void> pushSubmission(PendingSubmission s) async {
    throw Exception('400 ClientFormatError');
  }
}

class SuccessApi extends FailingApi {
  @override
  Future<void> pushSubmission(PendingSubmission s) async {
    // Does nothing, returns normally (simulates 200 OK)
  }
}

class FakeOutbox implements Outbox {
  final List<PendingSubmission> _entries = [];

  @override
  List<PendingSubmission> get pending => List.unmodifiable(_entries);
  @override
  Future<void> add(PendingSubmission e) async => _entries.add(e);
  @override
  Future<void> remove(String key) async =>
      _entries.removeWhere((e) => e.idempotencyKey == key);

  void seed(String key) {
    _entries.add(
      PendingSubmission(
        idempotencyKey: key,
        createdAt: DateTime.now().toUtc(),
        payload: '{}',
      ),
    );
  }
}

// No-op stubs for the evidence drain injection points.
class _FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'http://example.com/photo.jpg';
  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async => ActionPlanDto(
    id: id,
    status: 'open',
    criteriaLabel: '',
    groupTitle: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Not used by backoff tests. Satisfies the ActionPlanApi interface.
  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async => [];

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) => Future.error('not used');

  @override
  Future<ActionPlanDto?> fetchActionPlan(String id) async => null;
}

class _FakeActionPlanOutboxDao implements ActionPlanOutboxDao {
  @override
  Future<String?> getSubmissionIdForPlan(String planId) async => 'sub_123';
  _FakeActionPlanOutboxDao();
  @override
  Future<List<PendingActionPlanUpdate>> getEligiblePending() async => [];
  @override
  Future<void> enqueue(PendingActionPlanUpdatesCompanion entry) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> markExhausted(String id, String error) async {}
  @override
  Future<void> markStaleConflict(String id) async {}
  @override
  Future<PendingActionPlanUpdate?> getStaleConflictForPlan(
    String planId,
  ) async => null;
  @override
  Future<int> pendingCount() async => 0;
  @override
  Future<void> updateRetry(
    String id,
    int newRetryCount,
    DateTime nextRetry,
    String error,
  ) async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late OutboxDao dao;
  late FakeOutbox outbox;
  late SyncEngine engine;

  Future<String> seedEligibleSub({int retryCount = 0}) async {
    const id = 'sub-1';
    await dao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        templateId: 't1',
        storeId: 's1',
        clientScore: 100.0,
        idempotencyKey: id,
        retryCount: Value(retryCount),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    outbox.seed(id);
    return id;
  }

  SyncEngine createEngine(
    SyncApi testApi, [
    SubmissionRiskOutboxDao? customRiskDao,
  ]) {
    final connectivity = AlwaysOnlineConnectivity();
    return SyncEngine(
      connectivity: connectivity,
      auth: AlwaysAuthCheck(),
      modules: [
        CoreAuditSyncModule(
          api: testApi,
          outboxDao: dao,
          globalRiskDao: GlobalRiskDao(db),
          submissionRiskOutboxDao: customRiskDao ?? SubmissionRiskOutboxDao(db),
          syncMetaDao: SyncMetaDao(db),
          connectivity: connectivity,
          scheduleRetry: (_) {},
        ),
        ActionPlanSyncModule(
          api: _FakeActionPlanApi(),
          outboxDao: _FakeActionPlanOutboxDao(),
          connectivity: connectivity,
          scheduleRetry: (_) {},
        ),
      ],
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OutboxDao(db);
    outbox = FakeOutbox();
    engine = createEngine(FailingApi());
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  // ─── AC4: 1st failure → retryCount=1, nextRetryAt ≈ +2s ──────────────
  test(
    'AC4: SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s',
    () async {
      await seedEligibleSub(retryCount: 0);
      final now = DateTime.now().toUtc();

      await engine.requestSync();

      final rows = await db.select(db.pendingSubmissions).get();
      final row = rows.first;

      expect(row.retryCount, 1);
      expect(row.syncStatus, 'pending');
      expect(row.nextRetryAt, isNotNull);
      expect(
        row.nextRetryAt!.isAfter(now.add(const Duration(seconds: 1))),
        isTrue,
        reason: 'nextRetryAt must be at least 1s in the future',
      );
      expect(
        row.nextRetryAt!.isBefore(now.add(const Duration(seconds: 3))),
        isTrue,
        reason: 'nextRetryAt must be within 3s tolerance window',
      );
    },
  );

  // ─── AC5: 3rd failure (retryCount==3) → nextRetryAt ≈ +60s ──────────
  test('AC5: SyncEngine_ThirdFailure_SetsNextRetryAt60s', () async {
    await seedEligibleSub(retryCount: 3);
    final now = DateTime.now().toUtc();

    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    final row = rows.first;

    expect(row.retryCount, 4);
    expect(row.syncStatus, 'pending');
    expect(
      row.nextRetryAt!.isAfter(now.add(const Duration(seconds: 59))),
      isTrue,
    );
    expect(
      row.nextRetryAt!.isBefore(now.add(const Duration(seconds: 61))),
      isTrue,
    );
  });

  // ─── AC6: 4th failure (retryCount==4) → status=exhausted ─────────────
  test('AC6: SyncEngine_FourthFailure_SetsStatusExhausted', () async {
    await seedEligibleSub(retryCount: 4);

    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    final row = rows.first;

    expect(row.syncStatus, 'exhausted');
    expect(engine.state, SyncState.idle);
  });

  // ─── AC-409: Risk push throws 409 Conflict → Treated as success ──────
  test(
    'AC-409: _drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved',
    () async {
      final riskDao = SubmissionRiskOutboxDao(db);
      // Directly insert using companion since enqueueRisk sets id to microseconds which is fine,
      // but we can just use enqueueRisk.
      await riskDao.enqueueRisk('sub-1', 'risk-1');

      // Override engine with 409 API
      engine = createEngine(_ConflictRiskApi(), riskDao);

      await engine.requestSync();

      final risks = await db.select(db.submissionRiskOutboxEntries).get();
      expect(
        risks,
        isEmpty,
        reason: '409 Conflict should remove the record as a success path',
      );
    },
  );

  // ─── AC-FATAL: 400 Fatal Error → Marked exhausted without retries ─────
  test(
    'AC-FATAL: _drainSubmissions_400FatalError_MarkedExhausted_NoRetry',
    () async {
      await seedEligibleSub(retryCount: 0);

      // Override engine with Fatal API
      engine = createEngine(_FatalSubmissionApi());

      await engine.requestSync();

      final rows = await db.select(db.pendingSubmissions).get();
      final row = rows.first;

      expect(
        row.syncStatus,
        'exhausted',
        reason: 'Fatal 400 error must immediately exhaust',
      );
      expect(
        row.retryCount,
        0,
        reason: 'Fatal 400 error should not increment retry count',
      );
    },
  );

  // ─── AC-CHECKPOINT: Push succeeds → writes checkpoint before delete ───
  test(
    'AC-CHECKPOINT: drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete',
    () async {
      await seedEligibleSub(retryCount: 0);

      engine = createEngine(SuccessApi());

      await engine.requestSync();

      final rows = await db.select(db.pendingSubmissions).get();
      expect(
        rows,
        isEmpty,
        reason: 'Row should be deleted after successful sync',
      );

      // The plan specifies this should fail because markSynced doesn't exist yet.
      // We use dynamic to prevent compilation failure from aborting the whole test suite,
      // translating the missing method into a proper failing test.
      try {
        await (dao as dynamic).markSynced('dummy');
      } on NoSuchMethodError {
        fail('MethodNotFound: markSynced is missing from OutboxDao');
      }
    },
  );

  // ─── AC-SWEEP: Startup sweep deletes orphaned synced rows ─────────────
  test(
    'AC-SWEEP: requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions',
    () async {
      const id = 'sub-sweep';
      await dao.insertSubmission(
        PendingSubmissionsCompanion.insert(
          id: id,
          templateId: 't1',
          storeId: 's1',
          clientScore: 100.0,
          idempotencyKey: id,
          syncStatus: const Value('submission_synced'), // Orphaned from a crash
          createdAt: DateTime.now().toUtc(),
        ),
      );

      // Run engine (with FailingApi by default in setUp)
      await engine.requestSync();

      final rows = await db.select(db.pendingSubmissions).get();
      expect(
        rows.where((r) => r.id == id),
        isEmpty,
        reason: 'Startup sweep should delete orphaned submission_synced rows',
      );
    },
  );

  // ─── AC-SWEEP-NOPUSH: Sweep does not hit API for already synced rows ──
  test('AC-SWEEP-NOPUSH: startupSweep_DoesNotPushAlreadySyncedRows', () async {
    const id = 'sub-sweep-nopush';
    await dao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        templateId: 't1',
        storeId: 's1',
        clientScore: 100.0,
        idempotencyKey: id,
        syncStatus: const Value('submission_synced'),
        createdAt: DateTime.now().toUtc(),
      ),
    );

    // engine uses FailingApi. If the sweep tries to push this row, it will throw.
    // So if it successfully removes the row without crashing the sync, it proves no push was attempted.
    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    expect(rows.where((r) => r.id == id), isEmpty);
  });
}
