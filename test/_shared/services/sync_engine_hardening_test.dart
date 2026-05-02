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
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/pending_submission.dart';
import 'package:checkly/_shared/services/delta_pull_result.dart';
import 'package:checkly/_shared/services/pending_submission_risk.dart';
import 'package:checkly/_shared/services/sync_api.dart';

import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';
import 'package:checkly/features/action_plans/services/action_plan_sync_module.dart';

// Fakes
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

class FakeSyncApiFailingSubmissions implements SyncApi {
  int pushRiskCallCount = 0;

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    throw Exception('Network Error 503');
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async =>
      DeltaPullResult(serverTimestamp: DateTime.now());

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async => [];

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
    pushRiskCallCount++;
  }

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];

  @override
  Future<void> pushProgramEvidence(
    String assignmentId,
    List<Map<String, dynamic>> evidenceItems,
  ) async {}

  @override
  Future<void> pushProgramPhoto(String photoLocalKey, String filePath) async {}
}

class FakeActionPlanApiSpy implements ActionPlanApi {
  int updateCallCount = 0;

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> f,
  ) async {
    updateCallCount++;
    return ActionPlanDto(
      id: id,
      status: '',
      criteriaLabel: '',
      groupTitle: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'url';

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

void main() {
  late AppDatabase testDb;
  late OutboxDao outboxDao;
  late ActionPlanOutboxDao actionPlanOutboxDao;
  late SubmissionRiskOutboxDao riskOutboxDao;

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    outboxDao = OutboxDao(testDb);
    actionPlanOutboxDao = ActionPlanOutboxDao(testDb);
    riskOutboxDao = SubmissionRiskOutboxDao(testDb);
  });

  tearDown(() async => testDb.close());

  test(
    'TC-03: SyncEngine_SubmissionFailure_DoesNotBlock_ActionPlanDrain',
    () async {
      // Arrange
      final api = FakeSyncApiFailingSubmissions();
      final apApi = FakeActionPlanApiSpy();
      final connectivity = FakeConnectivity();
      final engine = SyncEngine(
        connectivity: connectivity,
        auth: FakeAuthCheck(),
        modules: [
          CoreAuditSyncModule(
            api: api,
            outboxDao: outboxDao,
            globalRiskDao: GlobalRiskDao(testDb),
            submissionRiskOutboxDao: riskOutboxDao,
            syncMetaDao: SyncMetaDao(testDb),
            connectivity: connectivity,
            scheduleRetry: (_) {},
          ),
          ActionPlanSyncModule(
            api: apApi,
            outboxDao: actionPlanOutboxDao,
            connectivity: connectivity,
            scheduleRetry: (_) {},
          ),
        ],
      );

      // Enqueue a submission that will fail
      await outboxDao.insertSubmissionWithAnswers(
        PendingSubmissionsCompanion.insert(
          id: 'sub-fail',
          idempotencyKey: 'idem',
          templateId: 'tpl',
          storeId: 'str',
          clientScore: 0.0,
          createdAt: DateTime.now(),
        ),
        [],
      );

      // Enqueue an action plan evidence
      await actionPlanOutboxDao.enqueue(
        PendingActionPlanUpdatesCompanion.insert(
          id: 'ap-out-1',
          actionPlanId: 'ap-1',
          correctionPlan: 'correction',
          evidenceNote: 'note',
          createdAt: DateTime.now(),
        ),
      );

      // Act
      await engine.requestSync();

      // Assert
      expect(
        apApi.updateCallCount,
        1,
        reason: 'Action Plan drain should run even if submission fails',
      );
    },
  );

  test('TC-04: SyncEngine_SubmissionFailure_DoesNotBlock_RiskDrain', () async {
    // Arrange
    final api = FakeSyncApiFailingSubmissions();
    final apApi = FakeActionPlanApiSpy();
    final connectivity = FakeConnectivity();
    final engine = SyncEngine(
      connectivity: connectivity,
      auth: FakeAuthCheck(),
      modules: [
        CoreAuditSyncModule(
          api: api,
          outboxDao: outboxDao,
          globalRiskDao: GlobalRiskDao(testDb),
          submissionRiskOutboxDao: riskOutboxDao,
          syncMetaDao: SyncMetaDao(testDb),
          connectivity: connectivity,
          scheduleRetry: (_) {},
        ),
        ActionPlanSyncModule(
          api: apApi,
          outboxDao: actionPlanOutboxDao,
          connectivity: connectivity,
          scheduleRetry: (_) {},
        ),
      ],
    );

    // Enqueue a submission that will fail
    await outboxDao.insertSubmissionWithAnswers(
      PendingSubmissionsCompanion.insert(
        id: 'sub-fail',
        idempotencyKey: 'idem',
        templateId: 'tpl',
        storeId: 'str',
        clientScore: 0.0,
        createdAt: DateTime.now(),
      ),
      [],
    );

    // Enqueue a risk
    await riskOutboxDao.enqueueRisk('sub-1', 'risk-1');

    // Act
    await engine.requestSync();

    // Assert
    expect(
      api.pushRiskCallCount,
      1,
      reason: 'Risk drain should run even if submission fails',
    );
  });
}
