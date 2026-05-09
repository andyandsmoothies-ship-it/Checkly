import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/action_plans/domain/action_plan.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/manager/action_plan_api.dart';

void main() {
  group('ActionPlan Entity Tests', () {
    late ActionPlanDto baseDto;

    setUp(() {
      baseDto = ActionPlanDto(
        id: 'plan-123',
        status: 'open',
        criteriaLabel: 'Clean floors',
        groupTitle: 'Cleanliness',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Helper to simulate DTO copyWith if it doesn't exist
    ActionPlanDto copyWithStatus(ActionPlanDto dto, String status) {
      return ActionPlanDto(
        id: dto.id,
        status: status,
        criteriaLabel: dto.criteriaLabel,
        groupTitle: dto.groupTitle,
        storeName: dto.storeName,
        storeId: dto.storeId,
        storeManagerName: dto.storeManagerName,
        rootCause: dto.rootCause,
        correctionPlan: dto.correctionPlan,
        evidencePhotoUrl: dto.evidencePhotoUrl,
        evidenceNote: dto.evidenceNote,
        closedAt: dto.closedAt,
        verifierName: dto.verifierName,
        evidenceSubmittedAt: dto.evidenceSubmittedAt,
        evidenceSubmittedByName: dto.evidenceSubmittedByName,
        deadline: dto.deadline,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
    }

    ActionPlanDto dtoWithEvidence(ActionPlanDto dto) {
      return ActionPlanDto(
        id: dto.id,
        status: 'pending_verify',
        criteriaLabel: dto.criteriaLabel,
        groupTitle: dto.groupTitle,
        correctionPlan: 'Fix it',
        evidencePhotoUrl: 'photo.jpg',
        evidenceNote: 'Fixed',
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
    }

    // TC-11-01
    test(
      'submitEvidence() throws RoleGuardException if role is not store_manager',
      () {
        final plan = ActionPlan(baseDto);
        expect(
          () => plan.submitEvidence(
            role: 'auditor',
            correctionPlan: 'Fix the floor',
            currentUserName: 'John',
            evidenceNote: 'Fixed',
            photoPath: null,
          ),
          throwsA(isA<RoleGuardException>()),
        );
      },
    );

    // TC-11-02
    test(
      'submitEvidence() throws InvalidTransitionException if status is not open',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'pending_verify'));
        expect(
          () => plan.submitEvidence(
            role: 'store_manager',
            correctionPlan: 'Fix the floor',
            currentUserName: 'John',
            evidenceNote: 'Fixed',
            photoPath: null,
          ),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    // TC-11-03
    test(
      'submitEvidence() throws InvalidTransitionException if status is closed',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'closed'));
        expect(
          () => plan.submitEvidence(
            role: 'store_manager',
            correctionPlan: 'Fix the floor',
            currentUserName: 'John',
            evidenceNote: 'Fixed',
            photoPath: null,
          ),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    // TC-11-04
    test('closePlan() throws RoleGuardException if role is store_manager', () {
      final plan = ActionPlan(copyWithStatus(baseDto, 'pending_verify'));
      expect(
        () => plan.closePlan(role: 'store_manager', verifierName: 'John'),
        throwsA(isA<RoleGuardException>()),
      );
    });

    // TC-11-05
    test(
      'closePlan() throws InvalidTransitionException if status is not pending_verify',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'open'));
        expect(
          () => plan.closePlan(role: 'auditor', verifierName: 'John'),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    // TC-11-06
    test(
      'rejectEvidence() throws RoleGuardException if role is store_manager',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'pending_verify'));
        expect(
          () =>
              plan.rejectEvidence(role: 'store_manager', reason: 'Still dirty'),
          throwsA(isA<RoleGuardException>()),
        );
      },
    );

    // TC-11-07
    test(
      'rejectEvidence() throws InvalidTransitionException if status is not pending_verify',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'closed'));
        expect(
          () => plan.rejectEvidence(role: 'admin', reason: 'Still dirty'),
          throwsA(isA<InvalidTransitionException>()),
        );
      },
    );

    // TC-11-08
    test(
      'submitEvidence() returns a new ActionPlan with status = pending_verify',
      () {
        final plan = ActionPlan(baseDto);
        final newPlan = plan.submitEvidence(
          role: 'store_manager',
          correctionPlan: 'Cleaned the floor thoroughly',
          currentUserName: 'StoreManager1',
          evidenceNote: 'Floor is clean',
          photoPath: 'path/to/photo.jpg',
        );

        expect(newPlan.dto.status, 'pending_verify');
        expect(newPlan.dto.correctionPlan, 'Cleaned the floor thoroughly');
        expect(newPlan.dto.evidenceNote, 'Floor is clean');
        expect(newPlan.dto.evidencePhotoUrl, 'path/to/photo.jpg');
        expect(newPlan.dto.evidenceSubmittedByName, 'StoreManager1');
        expect(newPlan.dto.evidenceSubmittedAt, isNotNull);
        expect(
          newPlan.dto.updatedAt.isAfter(baseDto.updatedAt) ||
              newPlan.dto.updatedAt.isAtSameMomentAs(baseDto.updatedAt),
          isTrue,
        );
        expect(newPlan.dto.id, 'plan-123'); // Unchanged
      },
    );

    // TC-11-09
    test(
      'closePlan() returns a new ActionPlan with status = closed and verifierName set',
      () {
        final plan = ActionPlan(copyWithStatus(baseDto, 'pending_verify'));
        final newPlan = plan.closePlan(
          role: 'area_manager',
          verifierName: 'Alice',
        );

        expect(newPlan.dto.status, 'closed');
        expect(newPlan.dto.verifierName, 'Alice');
        expect(newPlan.dto.closedAt, isNotNull);
      },
    );

    // TC-11-10
    test(
      'rejectEvidence() returns a new ActionPlan with status = open and evidence cleared',
      () {
        final plan = ActionPlan(dtoWithEvidence(baseDto));
        final newPlan = plan.rejectEvidence(
          role: 'auditor',
          reason: 'Missing clear photo',
        );

        expect(newPlan.dto.status, 'open');
        expect(newPlan.dto.evidenceNote, isNull);
        expect(newPlan.dto.evidencePhotoUrl, isNull);
      },
    );
  });
}
