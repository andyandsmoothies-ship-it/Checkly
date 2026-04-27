import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/database/app_database.dart';

// --- Mocks ---
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

  late ActionPlanManager manager;
  late MockActionPlanApi api;
  late MockUserRoleProvider userRole;
  late MockConnectivityService connectivity;
  late MockActionPlanOutboxDao outboxDao;

  setUp(() {
    api = MockActionPlanApi();
    userRole = MockUserRoleProvider();
    connectivity = MockConnectivityService();
    outboxDao = MockActionPlanOutboxDao();

    manager = ActionPlanManager(
      api: api,
      userRole: userRole,
      connectivity: connectivity,
      outboxDao: outboxDao,
    );
  });

  group('ActionPlanManager State Machine & Rules —', () {
    final openPlan = ActionPlanDto(
      id: 'p1',
      status: 'open',
      criteriaLabel: 'C1',
      groupTitle: 'G1',
      storeName: 'Store 1',
      storeManagerName: 'John',
      rootCause: 'Issue',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final pendingPlan = ActionPlanDto(
      id: 'p2',
      status: 'pending_verify',
      criteriaLabel: 'C1',
      groupTitle: 'G1',
      storeName: 'Store 1',
      storeManagerName: 'John',
      rootCause: 'Issue',
      correctionPlan: 'Fix it',
      evidenceNote: 'Fixed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('submitEvidence (store_manager)', () {
      test(
        'S1: succeeds online and updates status to pending_verify',
        () async {
          // Arrange
          when(() => userRole.role).thenReturn('store_manager');
          when(() => connectivity.isOnline).thenReturn(true);
          when(() => api.updateActionPlan(any(), any())).thenAnswer(
            (_) async => ActionPlanDto(
              id: 'p1',
              status: 'pending_verify',
              criteriaLabel: 'C1',
              groupTitle: 'G1',
              correctionPlan: 'Fix applied',
              evidenceNote: 'See photo',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          // Act
          final result = await manager.submitEvidence(
            openPlan,
            correctionPlan: 'Fix applied',
            evidenceNote: 'See photo',
            currentUserName: 'Test User',
          );

          // Assert
          expect(result.status, 'pending_verify');
          verify(
            () => api.updateActionPlan('p1', {
              'status': 'pending_verify',
              'correctionPlan': 'Fix applied',
              'evidenceNote': 'See photo',
            }),
          ).called(1);
        },
      );

      test('S2: enqueues to outbox when offline without calling API', () async {
        // Arrange
        when(() => userRole.role).thenReturn('store_manager');
        when(() => connectivity.isOnline).thenReturn(false);
        when(() => outboxDao.enqueue(any())).thenAnswer((_) async {});

        // Act
        final result = await manager.submitEvidence(
          openPlan,
          correctionPlan: 'Fix applied',
          evidenceNote: 'See photo',
          currentUserName: 'Test User',
        );

        // Assert
        expect(result.status, 'pending_verify');
        verify(() => outboxDao.enqueue(any())).called(1);
        verifyNever(() => api.updateActionPlan(any(), any()));
      });

      test(
        'S3: throws RoleGuardException if role is not store_manager',
        () async {
          // Arrange
          when(() => userRole.role).thenReturn('auditor');

          // Act & Assert
          expect(
            () => manager.submitEvidence(
              openPlan,
              correctionPlan: 'x',
              evidenceNote: 'x',
              currentUserName: 'Test User',
            ),
            throwsA(isA<RoleGuardException>()),
          );
        },
      );

      test(
        'S4: throws InvalidTransitionException if plan is not open',
        () async {
          // Arrange
          when(() => userRole.role).thenReturn('store_manager');

          // Act & Assert
          expect(
            () => manager.submitEvidence(
              pendingPlan,
              correctionPlan: 'x',
              evidenceNote: 'x',
              currentUserName: 'Test User',
            ),
            throwsA(isA<InvalidTransitionException>()),
          );
        },
      );
    });

    group('closePlan (auditor/admin)', () {
      test('S5: succeeds for auditor when pending_verify', () async {
        // Arrange
        when(() => userRole.role).thenReturn('auditor');
        when(() => api.updateActionPlan(any(), any())).thenAnswer(
          (_) async => ActionPlanDto(
            id: 'p2',
            status: 'closed',
            criteriaLabel: 'C1',
            groupTitle: 'G1',
            verifierName: 'Alice',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await manager.closePlan(
          pendingPlan,
          verifierName: 'Alice',
        );

        // Assert
        expect(result.status, 'closed');
        verify(
          () => api.updateActionPlan('p2', {
            'status': 'closed',
            'verifierName': 'Alice',
          }),
        ).called(1);
      });

      test('S6: throws RoleGuardException if role is store_manager', () async {
        // Arrange
        when(() => userRole.role).thenReturn('store_manager');

        // Act & Assert
        expect(
          () => manager.closePlan(pendingPlan, verifierName: 'Alice'),
          throwsA(isA<RoleGuardException>()),
        );
      });
    });

    group('rejectEvidence (auditor/admin)', () {
      test('S7: succeeds for admin when pending_verify', () async {
        // Arrange
        when(() => userRole.role).thenReturn('admin');
        when(() => api.updateActionPlan(any(), any())).thenAnswer(
          (_) async => ActionPlanDto(
            id: 'p2',
            status: 'open',
            criteriaLabel: 'C1',
            groupTitle: 'G1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await manager.rejectEvidence(pendingPlan);

        // Assert
        expect(result.status, 'open');
        verify(
          () => api.updateActionPlan('p2', {
            'status': 'open',
            'evidencePhotoUrl': null,
            'evidenceNote': null,
          }),
        ).called(1);
      });
    });

    group('isOverdue', () {
      test('S8: returns true if open and past deadline', () {
        final overduePlan = ActionPlanDto(
          id: 'p1',
          status: 'open',
          criteriaLabel: 'C1',
          groupTitle: 'G1',
          deadline: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(
          ActionPlanManager.isOverdue(overduePlan, now: DateTime.now()),
          isTrue,
        );
      });

      test('returns false if not open even if past deadline', () {
        final closedPlan = ActionPlanDto(
          id: 'p1',
          status: 'closed',
          criteriaLabel: 'C1',
          groupTitle: 'G1',
          deadline: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(
          ActionPlanManager.isOverdue(closedPlan, now: DateTime.now()),
          isFalse,
        );
      });
    });
  });
}
