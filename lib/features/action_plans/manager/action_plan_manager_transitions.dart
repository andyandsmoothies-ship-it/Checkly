part of 'action_plan_manager.dart';

/// SM submits correction evidence → status changes to `pending_verify`.
///
/// Guards: role must be `store_manager`, status must be `open`.
///
/// **Offline-first (P1 UX Fix):** If the device is offline, the payload is
/// written to `PendingActionPlanUpdates` (SQLite queue) and the in-memory
/// cache is updated optimistically so the UI reflects the change immediately.
/// When connectivity is restored, `SyncEngine` drains the queue.
Future<ActionPlanDto> _submitEvidenceLogic(
  ActionPlanManager manager,
  ActionPlanDto plan, {
  required String correctionPlan,
  required String? rootCause,
  required String currentUserName,
  String? evidenceNote,
  String? photoPath,
}) async {
  final entity = ActionPlan(plan);
  final updatedEntity = entity.submitEvidence(
    role: manager._userRole.role,
    correctionPlan: correctionPlan,
    rootCause: rootCause,
    currentUserName: currentUserName,
    evidenceNote: evidenceNote,
    photoPath: photoPath,
  );
  final optimistic = updatedEntity.dto;

  if (!manager._connectivity.isOnline) {
    // --- Offline path: queue and optimistic update ---
    await manager._outboxDao.enqueue(
      PendingActionPlanUpdatesCompanion(
        id: Value(plan.id),
        actionPlanId: Value(plan.id),
        correctionPlan: Value(correctionPlan),
        rootCause: Value(rootCause),
        evidenceNote: Value(evidenceNote ?? ''),
        photoPath: Value(photoPath),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );

    // Patch in-memory list so the UI reflects the change without a DB reload
    final List<ActionPlanDto> updated = manager.actionPlans.value
        .map<ActionPlanDto>((p) => p.id == plan.id ? optimistic : p)
        .toList();
    manager.actionPlans.value = updated;

    return optimistic;
  }

  // --- Online path: direct API call (original behavior) ---
  final Map<String, dynamic> updatePayload = {
    'status': 'pending_verify',
    'correctionPlan': correctionPlan,
    'rootCause': rootCause,
  };
  if (evidenceNote != null) {
    updatePayload['evidenceNote'] = evidenceNote;
  }

  if (photoPath != null && plan.submissionId != null) {
    final photoUrl = await manager._api.uploadPhoto(
      plan.submissionId!,
      photoPath,
    );
    updatePayload['evidencePhotoUrl'] = photoUrl;
  }

  final result = await manager._api.updateActionPlan(plan.id, updatePayload);

  // Patch in-memory list with the server response
  final List<ActionPlanDto> updated = manager.actionPlans.value
      .map<ActionPlanDto>((p) => p.id == plan.id ? result : p)
      .toList();
  manager.actionPlans.value = updated;

  return result;
}

/// Auditor/Admin closes a plan after verifying evidence.
///
/// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
Future<ActionPlanDto> _closePlanLogic(
  ActionPlanManager manager,
  ActionPlanDto plan, {
  required String verifierName,
  String? rootCause,
  String? correctionPlan,
}) async {
  final entity = ActionPlan(plan);
  entity.closePlan(
    role: manager._userRole.role,
    verifierName: verifierName,
    rootCause: rootCause,
    correctionPlan: correctionPlan,
  );

  return manager._api.updateActionPlan(plan.id, {
    'status': 'closed',
    'verifierName': verifierName,
    if (rootCause != null) 'rootCause': rootCause,
    if (correctionPlan != null) 'correctionPlan': correctionPlan,
  });
}

/// Auditor/Admin rejects evidence → status returns to `open`.
///
/// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
Future<ActionPlanDto> _rejectEvidenceLogic(
  ActionPlanManager manager,
  ActionPlanDto plan,
) async {
  final entity = ActionPlan(plan);
  entity.rejectEvidence(
    role: manager._userRole.role,
    reason:
        'reject evidence', // Unused in entity currently, but required by API
  );

  return manager._api.updateActionPlan(plan.id, {
    'status': 'open',
    'evidencePhotoUrl': null,
    'evidenceNote': null,
  });
}
