import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
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
import 'package:checkly/_shared/services/outbox.dart';
import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';
import 'package:checkly/features/action_plans/services/action_plan_sync_module.dart';

// ============================================================
// Fakes & Spies
// ============================================================

class FakeConnectivity implements ConnectivityService {
  @override
  bool isOnline;
  FakeConnectivity({this.isOnline = false});
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class FakeSyncApi implements SyncApi {
  String? lastPushedPayload;
  int pushCallCount = 0;

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    lastPushedPayload = submission.payload;
    pushCallCount++;
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async =>
      DeltaPullResult(serverTimestamp: DateTime.now());

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async => [];

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {}

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];
}

class FakeOutbox implements Outbox {
  @override
  List<PendingSubmission> get pending => [];
  @override
  Future<void> add(PendingSubmission e) async {}
  @override
  Future<void> remove(String key) async {}
}

class FakeAuthCheck implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

class FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<ActionPlanDto> updateActionPlan(String id, Map<String, dynamic> f) =>
      Future.error('not used');

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'mock_photo_url';

  /// Not used by sync engine push tests. Satisfies the ActionPlanApi interface.
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

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    outboxDao = OutboxDao(testDb);
    actionPlanOutboxDao = ActionPlanOutboxDao(testDb);
  });

  tearDown(() async => testDb.close());

  // ----------------------------------------------------------------
  // AC-2: SyncEngine Push phase serializes outbox answers accurately
  // Source: Contract 2
  // ----------------------------------------------------------------
  test(
    'SyncEngine_Push_BuildsCorrectPayloadFromNormalizedTables_AndClearsOutbox',
    () async {
      // Arrange
      final fakeSyncApi = FakeSyncApi();

      final connectivity = FakeConnectivity(isOnline: true);
      final engine = SyncEngine(
        connectivity: connectivity,
        auth: FakeAuthCheck(),
        modules: [
          CoreAuditSyncModule(
            api: fakeSyncApi,
            outboxDao: outboxDao,
            globalRiskDao: GlobalRiskDao(testDb),
            submissionRiskOutboxDao: SubmissionRiskOutboxDao(testDb),
            syncMetaDao: SyncMetaDao(testDb),
            connectivity: connectivity,
            scheduleRetry: (_) {},
          ),
          ActionPlanSyncModule(
            api: FakeActionPlanApi(),
            outboxDao: actionPlanOutboxDao,
            connectivity: connectivity,
            scheduleRetry: (_) {},
          ),
        ],
      );

      // Pre-seed — 1 pending submission, 2 answers directly into DAO
      final submissionId = 'test-sub-001';
      final idempotencyKey = 'idem-key-001';
      await outboxDao.insertSubmissionWithAnswers(
        PendingSubmissionsCompanion.insert(
          id: submissionId,
          idempotencyKey: idempotencyKey,
          templateId: 'tpl-001',
          storeId: 'store-001',
          clientScore: 85.0,
          createdAt: DateTime.now().toUtc(),
        ),
        [
          PendingAnswersCompanion.insert(
            id: 'ans-001',
            pendingSubmissionId: submissionId,
            criteriaId: 'c-001',
            value: const Value('conform'),
          ),
          PendingAnswersCompanion.insert(
            id: 'ans-002',
            pendingSubmissionId: submissionId,
            criteriaId: 'c-002',
            value: const Value('non_conform'),
          ),
        ],
      );

      // Act
      await engine.requestSync();

      // Assert
      expect(
        fakeSyncApi.pushCallCount,
        equals(1),
        reason: 'Exactly 1 push call expected for 1 pending submission.',
      );

      expect(
        fakeSyncApi.lastPushedPayload,
        isNotNull,
        reason:
            'Payload must be non-null — SyncEngine must build it from DAO rows.',
      );

      final decoded =
          jsonDecode(fakeSyncApi.lastPushedPayload!) as Map<String, dynamic>;
      expect(decoded['templateId'], equals('tpl-001'));
      expect(decoded['storeId'], equals('store-001'));
      expect(decoded['clientScore'], equals(85.0));
      expect(
        (decoded['answers'] as List).length,
        equals(2),
        reason: 'Payload must embed all 2 answers from pending_answers table.',
      );

      expect(
        (await outboxDao.getAllPending()).length,
        equals(0),
        reason: 'Outbox must be drained after successful push.',
      );
    },
  );
}
