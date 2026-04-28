// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'audit_manager.dart';

// ---------- Draft helpers ----------

/// Schedules a debounced draft save.
void _scheduleDraftSaveLogic(AuditManager manager) {
  if (manager._draftKey == null) return;
  final answersMap = manager._answers.map((k, v) => MapEntry(k, v.toJson()));
  manager._draftService.scheduleSave(
    draftKey: manager._draftKey!,
    answersMap: answersMap,
    notes: manager._notes,
  );
  manager._draftSavedAt = DateTime.now();
}

/// Restores answers from a loaded draft.
void _restoreDraftLogic(AuditManager manager) {
  final draft = manager._pendingDraft;
  if (draft == null) return;

  for (final entry in draft.answersMap.entries) {
    try {
      final restored = AuditAnswer.fromJson(entry.value);
      final existing = manager._answers[entry.key];
      if (existing != null) {
        existing.value = restored.value;
        existing.numericValue = restored.numericValue;
        existing.note = restored.note;
        existing.photoUrl = restored.photoUrl;
        existing.repeatedFaultCount = restored.repeatedFaultCount;
        existing.isCcp = restored.isCcp;
        existing.isRisk = restored.isRisk;
      }
    } catch (_) {
      // Skip corrupted answers
    }
  }

  if (draft.notes != null) manager._notes = draft.notes;
  manager._pendingDraft = null;
  manager._recalculateScore();
  manager.notifyListeners();
}

/// Discards the pending draft without restoring.
void _discardDraftLogic(AuditManager manager) {
  if (manager._draftKey != null) {
    manager._draftService.deleteDraft(manager._draftKey!);
  }
  manager._pendingDraft = null;
  _scheduleDraftSaveLogic(manager);
  manager.notifyListeners();
}

/// Forces an immediate synchronous lock to the local database,
/// bypassing the 3-second debounce. Use this before teardown.
Future<void> _forceSaveLogic(AuditManager manager) async {
  if (manager._draftKey == null) return;
  final answersMap = manager._answers.map((k, v) => MapEntry(k, v.toJson()));
  await manager._draftService.flushSave(
    draftKey: manager._draftKey!,
    answersMap: answersMap,
    notes: manager._notes,
  );
  manager._draftSavedAt = DateTime.now();
}
