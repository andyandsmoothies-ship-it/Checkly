import 'dart:async';
import 'package:dio/dio.dart';
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
import 'package:checkly/_shared/services/sync_state.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/_shared/services/pending_submission.dart';
import 'package:checkly/_shared/services/delta_pull_result.dart';
import 'package:checkly/_shared/services/pending_submission_risk.dart';
import 'package:checkly/_shared/services/sync_api.dart';
import 'package:checkly/_shared/services/auth_check.dart';

import 'package:checkly/features/action_plans/adapters/action_plan_api_adapter.dart';
import 'package:checkly/features/audit/services/core_audit_sync_module.dart';
import 'package:checkly/features/action_plans/services/action_plan_sync_module.dart';

import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/_shared/database/dao/profile_dao.dart';
import 'package:checkly/_shared/database/dao/submission_dao.dart';
import 'package:mocktail/mocktail.dart';

// =================================================================
// FAKES
// =================================================================
class FakeConnectivityService implements ConnectivityService {
  bool _isOnline = true;
  @override
  bool get isOnline => _isOnline;
  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
  final _controller = StreamController<bool>.broadcast(sync: true);
  void setOnline() => _isOnline = true;
  void dispose() => _controller.close();
}

class FakeSyncApi implements SyncApi {
  @override
  Future<void> pushSubmission(PendingSubmission submission) async {}
  @override
  Future<DeltaPullResult> pullDeltas({
    DateTime? cursorUpdatedAt,
    String? cursorId,
    String? storeId,
    String? areaId,
  }) async => DeltaPullResult(
    serverTimestamp: DateTime.now(),
    hasNextPage: false,
    submissions: [],
  );
  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async => [];
  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {}

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];
}

class FakeAuthCheck implements AuthCheck {
  @override
  bool get isLoggedIn => true;
}

class FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'http://example.com/photo.jpg';
  final List<String> calls = [];
  bool throwStaleException = false;

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async {
    calls.add(id);
    if (throwStaleException && id == 'stale-ap-id') {
      throw ActionPlanAlreadyClosedException();
    }
    return ActionPlanDto(
      id: id,
      status: fields['status'] ?? 'open',
      criteriaLabel: '',
      groupTitle: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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

// =================================================================
// MOCK DIO
// =================================================================
class MockDio implements Dio {
  int statusCode = 200;
  dynamic responseData;

  @override
  Future<Response<T>> put<T>(
    String path, {
    data,
    queryParameters,
    options,
    cancelToken,
    onSendProgress,
    onReceiveProgress,
  }) async {
    if (statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: statusCode,
          data: responseData,
        ),
      );
    }
    return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: responseData,
        )
        as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthManager extends Mock implements AuthManager {}

class MockProfileDao extends Mock implements ProfileDao {}

class MockSubmissionDao extends Mock implements SubmissionDao {}

void main() {
  group('SyncEngine ActionPlan Stale State Tests (Slice 2)', () {
    late AppDatabase db;
    late ActionPlanOutboxDao actionPlanOutboxDao;
    late FakeConnectivityService connectivity;
    late FakeActionPlanApi actionPlanApi;
    late SyncEngine engine;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      actionPlanOutboxDao = ActionPlanOutboxDao(db);
      connectivity = FakeConnectivityService();
      actionPlanApi = FakeActionPlanApi();

      engine = SyncEngine(
        connectivity: connectivity,
        auth: FakeAuthCheck(),
        modules: [
          CoreAuditSyncModule(
            api: FakeSyncApi(),
            outboxDao: OutboxDao(db),
            globalRiskDao: GlobalRiskDao(db),
            submissionRiskOutboxDao: SubmissionRiskOutboxDao(db),
            syncMetaDao: SyncMetaDao(db),
            connectivity: connectivity,
            scheduleRetry: (delay) {},
            authManager: MockAuthManager(),
            profileDao: MockProfileDao(),
            submissionDao: MockSubmissionDao(),
          ),
          ActionPlanSyncModule(
            api: actionPlanApi,
            outboxDao: actionPlanOutboxDao,
            connectivity: connectivity,
            scheduleRetry: (delay) {},
          ),
        ],
      );
    });

    tearDown(() async {
      engine.dispose();
      await db.close();
    });

    test(
      'FE-SYNC-AP-409-01: SyncEngine_WhenActionPlanApiThrowsActionPlanAlreadyClosedException_RemovesOutboxEntry_AndContinuesBatch',
      () async {
        // Arrange
        await actionPlanOutboxDao.enqueue(
          PendingActionPlanUpdatesCompanion.insert(
            id: 'entry-1',
            actionPlanId: 'stale-ap-id',
            correctionPlan: 'Fix 1',
            evidenceNote: '',
            createdAt: DateTime.now(),
          ),
        );
        await actionPlanOutboxDao.enqueue(
          PendingActionPlanUpdatesCompanion.insert(
            id: 'entry-2',
            actionPlanId: 'valid-ap-id',
            correctionPlan: 'Fix 2',
            evidenceNote: '',
            createdAt: DateTime.now(),
          ),
        );

        actionPlanApi.throwStaleException = true;

        // Act
        await engine.requestSync();

        // Assert
        expect(actionPlanApi.calls, ['stale-ap-id', 'valid-ap-id']);
        expect(
          engine.state,
          SyncState.idle,
        ); // Engine should not be in error state

        final pending = await actionPlanOutboxDao.getEligiblePending();
        expect(
          pending,
          isEmpty,
        ); // Both should be removed (one drained intentionally, one successful)
      },
    );

    test(
      'FL-SYNC-SC-01: SyncEngine_WhenActionPlanAlreadyClosed_MarksStaleConflict_AndContinuesBatch',
      () async {
        // Arrange
        await actionPlanOutboxDao.enqueue(
          PendingActionPlanUpdatesCompanion.insert(
            id: 'entry-1',
            actionPlanId: 'stale-ap-id',
            correctionPlan: 'Fix 1',
            evidenceNote: '',
            createdAt: DateTime.now(),
          ),
        );
        await actionPlanOutboxDao.enqueue(
          PendingActionPlanUpdatesCompanion.insert(
            id: 'entry-2',
            actionPlanId: 'valid-ap-id',
            correctionPlan: 'Fix 2',
            evidenceNote: '',
            createdAt: DateTime.now(),
          ),
        );

        actionPlanApi.throwStaleException = true;

        // Act
        await engine.requestSync();

        // Assert
        expect(actionPlanApi.calls, ['stale-ap-id', 'valid-ap-id']);
        expect(engine.state, SyncState.idle);

        // The stale record should NOT be removed, it should be marked as stale_conflict.
        final staleRows = await (db.select(
          db.pendingActionPlanUpdates,
        )..where((tbl) => tbl.id.equals('entry-1'))).get();
        expect(
          staleRows,
          isNotEmpty,
          reason: 'Stale entry-1 should NOT be deleted',
        );
        expect(
          staleRows.first.syncStatus,
          'stale_conflict',
          reason: 'Stale entry-1 should be marked as stale_conflict',
        );

        // The valid record SHOULD be removed because it was synced successfully.
        final validRows = await (db.select(
          db.pendingActionPlanUpdates,
        )..where((tbl) => tbl.id.equals('entry-2'))).get();
        expect(validRows, isEmpty, reason: 'Valid entry-2 should be removed');
      },
    );
  });

  group('ActionPlanApiAdapter Stale State Tests (Slice 2)', () {
    late MockDio dio;
    late ActionPlanApiAdapter adapter;

    setUp(() {
      dio = MockDio();
      adapter = ActionPlanApiAdapter(dio);
    });

    test(
      'FE-SYNC-AP-409-02: ActionPlanApiAdapter_WhenServerReturns409ProblemDetailsCodeActionPlanAlreadyClosed_ThrowsTypedActionPlanAlreadyClosedException',
      () async {
        // Arrange
        dio.statusCode = 409;
        dio.responseData = {
          'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.10',
          'title': 'Conflict',
          'status': 409,
          'extensions': {'code': 'action_plan_already_closed'},
        };

        // Act & Assert
        // We expect the ActionPlanAlreadyClosedException (the real one in action_plan_manager.dart or the stub here)
        // Since Dart Exception matching is type-based, we will check if the thrown error's runtime type matches.
        try {
          await adapter.updateActionPlan('id', {'status': 'pending_verify'});
          fail('Should have thrown an exception');
        } catch (e) {
          expect(
            e.runtimeType.toString(),
            'ActionPlanAlreadyClosedException',
            reason: 'Must throw a typed ActionPlanAlreadyClosedException',
          );
        }
      },
    );

    test(
      'ActionPlanApiAdapter_WhenServerReturnsGeneric409_ThrowsDioException',
      () async {
        // Arrange
        dio.statusCode = 409;
        dio.responseData = {'message': 'Some other conflict'};

        // Act & Assert
        try {
          await adapter.updateActionPlan('id', {'status': 'pending_verify'});
          fail('Should have thrown an exception');
        } catch (e) {
          expect(
            e,
            isA<DioException>(),
            reason:
                'Must rethrow DioException if code is not action_plan_already_closed',
          );
        }
      },
    );
  });
}
