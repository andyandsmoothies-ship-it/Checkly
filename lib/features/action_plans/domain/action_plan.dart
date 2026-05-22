import '../model/action_plan_dto.dart';
import '../manager/action_plan_api.dart';
import '../../../_shared/constants/action_plan_actions.dart';
import '../../../_shared/constants/user_persona.dart';

class ActionPlan {
  final ActionPlanDto dto;

  const ActionPlan(this.dto);

  void _assertNotTerminal() {
    if (dto.status == 'closed') {
      throw const InvalidTransitionException(
        'Cannot transition from closed state',
      );
    }
  }

  void _assertRole(
    String currentRole,
    List<UserPersona> allowedPersonas,
    String action,
  ) {
    if (!allowedPersonas.contains(UserPersona.fromRole(currentRole))) {
      throw RoleGuardException('Role "$currentRole" cannot $action');
    }
  }

  void _assertStatus(String requiredStatus, String targetStatus) {
    if (dto.status != requiredStatus) {
      throw InvalidTransitionException(
        'Cannot transition from "${dto.status}" to "$targetStatus"',
      );
    }
  }

  ActionPlan submitEvidence({
    required String role,
    required String correctionPlan,
    required String currentUserName,
    String? evidenceNote,
    String? photoPath,
  }) {
    _assertNotTerminal();
    _assertRole(role, [UserPersona.storeManager], 'submit evidence');
    _assertStatus('open', 'pending_verify');

    final optimisticDto = ActionPlanDto(
      id: dto.id,
      status: 'pending_verify',
      criteriaLabel: dto.criteriaLabel,
      groupTitle: dto.groupTitle,
      storeName: dto.storeName,
      storeId: dto.storeId,
      storeManagerName: dto.storeManagerName,
      sourceTitle: dto.sourceTitle,
      rootCause: dto.rootCause,
      correctionPlan: correctionPlan,
      evidencePhotoUrl: photoPath ?? dto.evidencePhotoUrl,
      evidenceNote: evidenceNote,
      closedAt: dto.closedAt,
      verifierName: dto.verifierName,
      evidenceSubmittedAt: DateTime.now().toUtc(),
      evidenceSubmittedByName: currentUserName,
      deadline: dto.deadline,
      createdAt: dto.createdAt,
      updatedAt: DateTime.now(),
      submissionId: dto.submissionId,
      allowedActions: const [ActionPlanActions.view],
      syncStatus: dto.syncStatus,
    );

    return ActionPlan(optimisticDto);
  }

  ActionPlan closePlan({required String role, required String verifierName}) {
    _assertNotTerminal();
    _assertRole(role, [
      UserPersona.auditor,
      UserPersona.admin,
      UserPersona.areaManager,
    ], 'close plan');
    _assertStatus('pending_verify', 'closed');

    final optimisticDto = ActionPlanDto(
      id: dto.id,
      status: 'closed',
      criteriaLabel: dto.criteriaLabel,
      groupTitle: dto.groupTitle,
      storeName: dto.storeName,
      storeId: dto.storeId,
      storeManagerName: dto.storeManagerName,
      sourceTitle: dto.sourceTitle,
      rootCause: dto.rootCause,
      correctionPlan: dto.correctionPlan,
      evidencePhotoUrl: dto.evidencePhotoUrl,
      evidenceNote: dto.evidenceNote,
      closedAt: DateTime.now().toUtc(),
      verifierName: verifierName,
      evidenceSubmittedAt: dto.evidenceSubmittedAt,
      evidenceSubmittedByName: dto.evidenceSubmittedByName,
      deadline: dto.deadline,
      createdAt: dto.createdAt,
      updatedAt: DateTime.now(),
      submissionId: dto.submissionId,
      allowedActions: const [ActionPlanActions.view],
      syncStatus: dto.syncStatus,
    );

    return ActionPlan(optimisticDto);
  }

  ActionPlan rejectEvidence({required String role, required String reason}) {
    _assertNotTerminal();
    _assertRole(role, [
      UserPersona.auditor,
      UserPersona.admin,
      UserPersona.areaManager,
    ], 'reject evidence');
    _assertStatus('pending_verify', 'open');

    final optimisticDto = ActionPlanDto(
      id: dto.id,
      status: 'open',
      criteriaLabel: dto.criteriaLabel,
      groupTitle: dto.groupTitle,
      storeName: dto.storeName,
      storeId: dto.storeId,
      storeManagerName: dto.storeManagerName,
      sourceTitle: dto.sourceTitle,
      rootCause: dto.rootCause,
      correctionPlan: dto.correctionPlan,
      evidencePhotoUrl: null,
      evidenceNote: null,
      closedAt: dto.closedAt,
      verifierName: dto.verifierName,
      evidenceSubmittedAt: dto.evidenceSubmittedAt,
      evidenceSubmittedByName: dto.evidenceSubmittedByName,
      deadline: dto.deadline,
      createdAt: dto.createdAt,
      updatedAt: DateTime.now(),
      submissionId: dto.submissionId,
      allowedActions: const [
        ActionPlanActions.view,
        ActionPlanActions.submitEvidence,
      ],
      syncStatus: dto.syncStatus,
    );

    return ActionPlan(optimisticDto);
  }
}
