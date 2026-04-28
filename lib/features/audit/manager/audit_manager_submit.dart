// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'audit_manager.dart';

// ---------- Submit (offline-first) ----------
Future<void> _submitAuditLogic(AuditManager manager) async {
  if (manager._template == null || manager._storeId == null) return;

  // Mutex guard — drop second concurrent call silently (AC-4)
  if (manager._isSubmitting) return;

  manager._isSubmitting = true;
  manager._error = null;
  manager._wasQueuedOffline = false;
  // Cancel any pending draft save before submit
  manager._draftService.dispose();
  manager.notifyListeners();

  try {
    manager._recalculateScore();

    final idempotencyKey = _uuid.v4();
    final now = DateTime.now();
    final submissionId = manager._pendingSubmissionId ?? _uuid.v4();

    if (manager._answers.isEmpty) {
      throw Exception(
        'Cannot submit an audit with zero answers. Please complete the audit first.',
      );
    }

    // 1. Build answer companions
    final answerCompanions = manager._answers.values.map((a) {
      return PendingAnswersCompanion.insert(
        id: _uuid.v4(),
        pendingSubmissionId: submissionId,
        criteriaId: a.criteriaId,
        value: Value(a.value),
        numericValue: Value(a.numericValue),
        note: Value(a.note),
        photoUrl: Value(a.photoUrl),
        isRepeatedError: Value(a.isRepeatedError),
        repeatedFaults: Value(a.repeatedFaultCount),
        isCcp: Value(a.isCcp),
        isRisk: Value(a.isRisk),
      );
    }).toList();

    // 2. Atomically persist submission + answers to outbox
    await manager._outbox.insertSubmissionWithAnswers(
      PendingSubmissionsCompanion.insert(
        id: submissionId,
        idempotencyKey: idempotencyKey,
        templateId: manager._template!.id,
        storeId: manager._storeId!,
        clientScore: manager._liveScore ?? 0.0,
        sectionScores: Value(manager._buildSectionScoresJson()),
        notes: Value(manager._notes),
        gpsLat: Value(manager._gpsLat),
        gpsLng: Value(manager._gpsLng),
        createdAt: now,
        syncStatus: Value('pending'),
        targetSubmissionId: Value(manager._targetSubmissionId),
      ),
      answerCompanions,
    );

    // 2.5. Delete draft now that submission is safely in outbox (atomic)

    if (manager._draftKey != null) {
      await manager._draftService.deleteDraft(manager._draftKey!);
      manager._draftKey =
          null; // Prevent PopScope from resurrecting the draft on navigation teardown
      manager._draftSavedAt = null;
    }

    // 3. Notify SyncEngine — it drains the outbox in the background (non-blocking).
    //    Connectivity state is used only to set the correct UX flag.
    final isOnline = manager._connectivity?.isOnline ?? true;
    manager._wasQueuedOffline = !isOnline;
    // Guard: SyncEngine may not be registered in test environments.
    try {
      unawaited(_di<SyncEngine>().requestSync());
    } catch (_) {
      // SyncEngine not registered (test/isolated environment) — outbox will drain on next connectivity event.
    }
  } catch (e) {
    manager._error = 'Submission failed. Please try again.';
  } finally {
    manager._isSubmitting = false;
    manager.notifyListeners();
  }
}
