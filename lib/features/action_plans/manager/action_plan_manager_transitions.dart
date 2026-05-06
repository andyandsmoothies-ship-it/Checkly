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
  required String currentUserName,
  String? evidenceNote,
  String? photoPath,
}) async {
  manager._assertNotTerminal(plan);
  manager._assertRole(['store_manager'], 'submit evidence');
  manager._assertStatus(plan, 'open', 'pending_verify');

  if (!manager._connectivity.isOnline) {
    // --- Offline path: queue and optimistic update ---
    const uuid = Uuid();
    await manager._outboxDao.enqueue(
      PendingActionPlanUpdatesCompanion(
        id: Value(uuid.v4()),
        actionPlanId: Value(plan.id),
        correctionPlan: Value(correctionPlan),
        evidenceNote: Value(evidenceNote ?? ''),
        photoPath: Value(photoPath),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );

    // Build the optimistic DTO so the UI transitions instantly
    final optimistic = ActionPlanDto(
      id: plan.id,
      status: 'pending_verify',
      criteriaLabel: plan.criteriaLabel,
      groupTitle: plan.groupTitle,
      storeName: plan.storeName,
      storeManagerName: plan.storeManagerName,
      rootCause: plan.rootCause,
      correctionPlan: correctionPlan,
      evidencePhotoUrl: photoPath ?? plan.evidencePhotoUrl,
      evidenceNote: evidenceNote,
      closedAt: plan.closedAt,
      verifierName: plan.verifierName,
      evidenceSubmittedAt: DateTime.now().toUtc(),
      evidenceSubmittedByName: currentUserName,
      deadline: plan.deadline,
      createdAt: plan.createdAt,
      updatedAt: DateTime.now(),
    );

    // Patch in-memory list so the UI reflects the change without a DB reload
    final updated = manager.actionPlans.value
        .map((p) => p.id == plan.id ? optimistic : p)
        .toList();
    manager.actionPlans.value = updated;

    return optimistic;
  }

  // --- Online path: direct API call (original behavior) ---
  final Map<String, dynamic> updatePayload = {
    'status': 'pending_verify',
    'correctionPlan': correctionPlan,
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
  final updated = manager.actionPlans.value
      .map((p) => p.id == plan.id ? result : p)
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
}) async {
  manager._assertNotTerminal(plan);
  manager._assertRole(['auditor', 'admin', 'area_manager'], 'close plan');
  manager._assertStatus(plan, 'pending_verify', 'closed');

  return manager._api.updateActionPlan(plan.id, {
    'status': 'closed',
    'verifierName': verifierName,
  });
}

/// Auditor/Admin rejects evidence → status returns to `open`.
///
/// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
Future<ActionPlanDto> _rejectEvidenceLogic(
  ActionPlanManager manager,
  ActionPlanDto plan,
) async {
  manager._assertNotTerminal(plan);
  manager._assertRole(['auditor', 'admin', 'area_manager'], 'reject evidence');
  manager._assertStatus(plan, 'pending_verify', 'open');

  return manager._api.updateActionPlan(plan.id, {
    'status': 'open',
    'evidencePhotoUrl': null,
    'evidenceNote': null,
  });
}
