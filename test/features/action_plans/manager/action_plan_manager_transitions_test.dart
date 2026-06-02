import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/user_role_provider.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/app_database.dart';

class MockActionPlanApi extends Mock implements ActionPlanApi {}

class MockUserRoleProvider extends Mock implements UserRoleProvider {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockActionPlanOutboxDao extends Mock implements ActionPlanOutboxDao {}

class FakePendingActionPlanUpdatesCompanion extends Fake
    implements PendingActionPlanUpdatesCompanion {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePendingActionPlanUpdatesCompanion());
  });

  group('ActionPlanManager Transitions', () {
    late ActionPlanManager manager;
    late MockActionPlanApi mockApi;
    late MockUserRoleProvider mockRoleProvider;
    late MockConnectivityService mockConnectivity;
    late MockActionPlanOutboxDao mockOutboxDao;

    ActionPlanDto createPlan({required String status}) {
      return ActionPlanDto(
        id: 'plan-123',
        status: status,
        criteriaLabel: 'Clean floors',
        groupTitle: 'Cleanliness',
        storeName: 'Store A',
        storeId: 'store-a',
        storeManagerName: 'Manager A',
        rootCause: null,
        correctionPlan: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    setUp(() {
      mockApi = MockActionPlanApi();
      mockRoleProvider = MockUserRoleProvider();
      mockConnectivity = MockConnectivityService();
      mockOutboxDao = MockActionPlanOutboxDao();

      manager = ActionPlanManager(
        api: mockApi,
        userRole: mockRoleProvider,
        connectivity: mockConnectivity,
        outboxDao: mockOutboxDao,
      );
    });

    test(
      'TC-10-01: submitEvidence asserts store_manager role and open status',
      () async {
        when(() => mockRoleProvider.role).thenReturn('auditor');
        final plan = createPlan(status: 'open');

        expect(
          () => manager.submitEvidence(
            plan,
            correctionPlan: 'Will clean',
            rootCause: null,
            currentUserName: 'Auditor A',
          ),
          throwsA(isA<RoleGuardException>()),
        );

        when(() => mockRoleProvider.role).thenReturn('store_manager');
        final closedPlan = createPlan(status: 'pending_verify');

        expect(
          () => manager.submitEvidence(
            closedPlan,
            correctionPlan: 'Will clean',
            rootCause: null,
            currentUserName: 'Manager A',
          ),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    test(
      'TC-10-02: submitEvidence online delegates to API and updates memory',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        when(() => mockConnectivity.isOnline).thenReturn(true);

        final plan = createPlan(status: 'open');
        manager.actionPlans.value = [plan];

        final updatedPlan = createPlan(status: 'pending_verify');
        when(
          () => mockApi.updateActionPlan('plan-123', any()),
        ).thenAnswer((_) async => updatedPlan);

        final result = await manager.submitEvidence(
          plan,
          correctionPlan: 'Fix it',
          rootCause: null,
          currentUserName: 'Manager A',
        );

        expect(result.status, 'pending_verify');
        expect(manager.actionPlans.value.first.status, 'pending_verify');
        verify(() => mockApi.updateActionPlan('plan-123', any())).called(1);
        verifyNever(() => mockOutboxDao.enqueue(any()));
      },
    );

    test(
      'TC-10-03: submitEvidence offline writes to OutboxDao and patches UI optimism',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        when(() => mockConnectivity.isOnline).thenReturn(false);

        final plan = createPlan(status: 'open');
        manager.actionPlans.value = [plan];

        when(() => mockOutboxDao.enqueue(any())).thenAnswer((_) async {});

        final result = await manager.submitEvidence(
          plan,
          correctionPlan: 'Fix it offline',
          rootCause: null,
          currentUserName: 'Manager A',
        );

        expect(result.status, 'pending_verify');
        expect(manager.actionPlans.value.first.status, 'pending_verify');
        expect(
          manager.actionPlans.value.first.correctionPlan,
          'Fix it offline',
        );

        verify(() => mockOutboxDao.enqueue(any())).called(1);
        verifyNever(() => mockApi.updateActionPlan(any(), any()));
      },
    );

    test(
      'TC-10-04: closePlan asserts auditor/admin role and pending_verify status',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        final plan = createPlan(status: 'pending_verify');

        expect(
          () => manager.closePlan(plan, verifierName: 'Manager A'),
          throwsA(isA<RoleGuardException>()),
        );

        when(() => mockRoleProvider.role).thenReturn('auditor');
        final openPlan = createPlan(status: 'open');

        expect(
          () => manager.closePlan(openPlan, verifierName: 'Auditor A'),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    test(
      'TC-10-05: closePlan calls API with verifierName and updates status',
      () async {
        when(() => mockRoleProvider.role).thenReturn('auditor');
        final plan = createPlan(status: 'pending_verify');

        final updatedPlan = createPlan(status: 'closed');
        when(
          () => mockApi.updateActionPlan('plan-123', any()),
        ).thenAnswer((_) async => updatedPlan);

        final result = await manager.closePlan(plan, verifierName: 'Auditor A');

        expect(result.status, 'closed');
        verify(
          () => mockApi.updateActionPlan('plan-123', {
            'status': 'closed',
            'verifierName': 'Auditor A',
          }),
        ).called(1);
      },
    );

    test(
      'TC-10-06: rejectEvidence asserts auditor/admin role and pending_verify status',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        final plan = createPlan(status: 'pending_verify');

        expect(
          () => manager.rejectEvidence(plan),
          throwsA(isA<RoleGuardException>()),
        );

        when(() => mockRoleProvider.role).thenReturn('admin');
        final openPlan = createPlan(status: 'open');

        expect(
          () => manager.rejectEvidence(openPlan),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    test(
      'TC-10-07: rejectEvidence clears evidence and returns to open status',
      () async {
        when(() => mockRoleProvider.role).thenReturn('admin');
        final plan = createPlan(status: 'pending_verify');

        final updatedPlan = createPlan(status: 'open');
        when(
          () => mockApi.updateActionPlan('plan-123', any()),
        ).thenAnswer((_) async => updatedPlan);

        final result = await manager.rejectEvidence(plan);

        expect(result.status, 'open');
        verify(
          () => mockApi.updateActionPlan('plan-123', {
            'status': 'open',
            'evidencePhotoUrl': null,
            'evidenceNote': null,
          }),
        ).called(1);
      },
    );

    test('TC-10-08: Transitions throw on terminal plan status', () async {
      when(() => mockRoleProvider.role).thenReturn('store_manager');
      final closedPlan = createPlan(status: 'closed');

      expect(
        () => manager.submitEvidence(
          closedPlan,
          correctionPlan: 'Late evidence',
          rootCause: null,
          currentUserName: 'Manager A',
        ),
        throwsA(isA<InvalidTransitionException>()),
      );

      when(() => mockRoleProvider.role).thenReturn('auditor');
      expect(
        () => manager.closePlan(closedPlan, verifierName: 'Auditor A'),
        throwsA(isA<InvalidTransitionException>()),
      );

      expect(
        () => manager.rejectEvidence(closedPlan),
        throwsA(isA<InvalidTransitionException>()),
      );
    });

    test(
      'submitEvidence online includes rootCause in the API call payload',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        when(() => mockConnectivity.isOnline).thenReturn(true);

        final plan = createPlan(status: 'open');
        manager.actionPlans.value = [plan];

        final updatedPlan = createPlan(status: 'pending_verify');
        when(
          () => mockApi.updateActionPlan('plan-123', any()),
        ).thenAnswer((_) async => updatedPlan);

        await manager.submitEvidence(
          plan,
          correctionPlan: 'Fix it',
          rootCause: 'Leaky pipe',
          currentUserName: 'Manager A',
        );

        verify(
          () => mockApi.updateActionPlan('plan-123', {
            'status': 'pending_verify',
            'correctionPlan': 'Fix it',
            'rootCause': 'Leaky pipe',
          }),
        ).called(1);
      },
    );

    test(
      'submitEvidence offline enqueues PendingActionPlanUpdatesCompanion with rootCause',
      () async {
        when(() => mockRoleProvider.role).thenReturn('store_manager');
        when(() => mockConnectivity.isOnline).thenReturn(false);

        final plan = createPlan(status: 'open');
        manager.actionPlans.value = [plan];

        when(() => mockOutboxDao.enqueue(any())).thenAnswer((_) async {});

        await manager.submitEvidence(
          plan,
          correctionPlan: 'Fix it offline',
          rootCause: 'Broken floor tile',
          currentUserName: 'Manager A',
        );

        final captured = verify(() => mockOutboxDao.enqueue(captureAny())).captured.first as PendingActionPlanUpdatesCompanion;
        expect(captured.rootCause.value, 'Broken floor tile');
      },
    );

    test(
      'closePlan online includes revised rootCause and correctionPlan in API call payload',
      () async {
        when(() => mockRoleProvider.role).thenReturn('auditor');
        final plan = createPlan(status: 'pending_verify');

        final updatedPlan = createPlan(status: 'closed');
        when(
          () => mockApi.updateActionPlan('plan-123', any()),
        ).thenAnswer((_) async => updatedPlan);

        await manager.closePlan(
          plan,
          verifierName: 'Auditor A',
          rootCause: 'Revised root cause',
          correctionPlan: 'Revised correction plan',
        );

        verify(
          () => mockApi.updateActionPlan('plan-123', {
            'status': 'closed',
            'verifierName': 'Auditor A',
            'rootCause': 'Revised root cause',
            'correctionPlan': 'Revised correction plan',
          }),
        ).called(1);
      },
    );
  });
}
