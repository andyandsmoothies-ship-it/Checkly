// ATDD: Slice 4.1 — SyncEngine Global Risks
// Status: 🔴 RED — production classes do not exist yet

import 'dart:async';
import 'package:drift/native.dart';
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
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';
import 'package:checkly/features/action_plans/services/action_plan_sync_module.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/_shared/database/dao/profile_dao.dart';
import 'package:checkly/_shared/database/dao/submission_dao.dart';
import 'package:mocktail/mocktail.dart';
class FakeConnectivity implements ConnectivityService {
  @override
  bool isOnline = true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class FakeAuthCheck implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

class FakeOutbox implements Outbox {
  @override
  List<PendingSubmission> get pending => [];
  @override
  Future<void> add(PendingSubmission e) async {}
  @override
  Future<void> remove(String key) async {}
}

class _FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'http://example.com/photo.jpg';
  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> f,
  ) async => throw UnimplementedError();
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

class FakeSyncApi implements SyncApi {
  int pullRisksCallCount = 0;
  int pushRisksCallCount = 0;
  List<PendingSubmissionRisk> pushedRisks = [];
  bool throw409 = false;

  @override
  Future<DeltaPullResult> pullDeltas({DateTime? cursorUpdatedAt, String? cursorId, String? storeId, String? areaId,}) async {
    return DeltaPullResult(serverTimestamp: DateTime.now(), hasNextPage: false, submissions: []);
  }

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {}

  // NEW INTERFACES (Should fail to compile until added to SyncApi)
  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async {
    pullRisksCallCount++;
    return [
      {
        'id': 'risk-1',
        'label': 'Test Risk 1',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
    pushRisksCallCount++;
    pushedRisks.add(risk);
    if (throw409) {
      throw Exception('DioException [409 Conflict]');
    }
  }

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];

}

class MockAuthManager extends Mock implements AuthManager {}
class MockProfileDao extends Mock implements ProfileDao {}
class MockSubmissionDao extends Mock implements SubmissionDao {}


void main() {
  late AppDatabase testDb;
  late SyncEngine engine;
  late FakeSyncApi fakeApi;
  late GlobalRiskDao globalRiskDao;
  late SubmissionRiskOutboxDao riskOutboxDao;

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    fakeApi = FakeSyncApi();
    globalRiskDao = GlobalRiskDao(testDb);
    riskOutboxDao = SubmissionRiskOutboxDao(testDb);

    final connectivity = FakeConnectivity();
    engine = SyncEngine(
      connectivity: connectivity,
      auth: FakeAuthCheck(),
      modules: [
        CoreAuditSyncModule(
          api: fakeApi,
          outboxDao: OutboxDao(testDb),
          globalRiskDao: globalRiskDao,
          submissionRiskOutboxDao: riskOutboxDao,
          syncMetaDao: SyncMetaDao(testDb),
          connectivity: connectivity,
          scheduleRetry: (delay) {},
          authManager: MockAuthManager(),
          profileDao: MockProfileDao(),
          submissionDao: MockSubmissionDao(),
        ),
        ActionPlanSyncModule(
          api: _FakeActionPlanApi(),
          outboxDao: _FakeActionPlanOutboxDao(),
          connectivity: connectivity,
          scheduleRetry: (delay) {},
        ),
      ],
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  // T1: SyncEngine pulls delta GlobalRisks and stores in CachedGlobalRisks
  test(
    'T1: SyncEngine pulls delta GlobalRisks and stores in CachedGlobalRisks',
    () async {
      await engine.requestSync();

      expect(fakeApi.pullRisksCallCount, 1);

      final cached = await globalRiskDao.getAllRisks();
      expect(cached.length, 1);
      expect(cached.first.id, 'risk-1');
    },
  );

  // T2: SyncEngine pushes PendingSubmissionRisk and removes from outbox
  test(
    'T2: SyncEngine pushes PendingSubmissionRisk and removes from outbox',
    () async {
      // Seed outbox
      await riskOutboxDao.enqueueRisk('sub-1', 'risk-1');

      await engine.requestSync();

      expect(fakeApi.pushRisksCallCount, 1);
      expect(fakeApi.pushedRisks.first.submissionId, 'sub-1');
      expect(fakeApi.pushedRisks.first.globalRiskId, 'risk-1');

      final pending = await riskOutboxDao.getEligiblePending();
      expect(pending, isEmpty, reason: 'Outbox should be drained');
    },
  );

  // T3: SyncEngine treats 409 Conflict on Push as successful drain
  test(
    'T3: SyncEngine treats 409 Conflict on Push as successful drain',
    () async {
      // Seed outbox
      await riskOutboxDao.enqueueRisk('sub-1', 'risk-1');
      fakeApi.throw409 = true;

      await engine.requestSync();

      expect(fakeApi.pushRisksCallCount, 1);

      // Even though it threw 409, the engine should consider it a success and remove from outbox
      final pending = await riskOutboxDao.getEligiblePending();
      expect(
        pending,
        isEmpty,
        reason: '409 Conflict means it already exists, outbox should drain',
      );
    },
  );
}
