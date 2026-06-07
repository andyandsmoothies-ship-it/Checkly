// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'audit_manager.dart';

// ---------- Scoring helpers ----------

/// Recalculates the live score and section scores.
void _recalculateScoreLogic(AuditManager manager) {
  if (manager._template == null) return;
  final input = ScoringInputMapper.fromTemplate(
    manager._template!,
    manager._answers,
    hasGlobalRisk: manager._triggeredRiskIds.isNotEmpty,
  );
  final result = ScoringEngine.calculate(input);
  manager._liveScore = result.totalScore;
  manager._sectionScores = result.sectionScores;
}

/// Builds the section scores JSON payload.
String _buildSectionScoresJsonLogic(AuditManager manager) {
  if (manager._template == null) return '{}';
  final sections = <String, dynamic>{};
  for (final group in manager._template!.groups) {
    final secScore = manager._sectionScores[group.id];
    sections[group.id] = {
      'title': group.title,
      'weight': group.weight,
      'maxPoints': secScore?.maxPoints ?? 0.0,
      'score': secScore?.score ?? 0.0,
      'maxScore': secScore?.maxPoints ?? 0.0,
    };
  }
  return jsonEncode(sections);
}

/// Recalculates the score debounced by 200ms.
void _recalculateScoreDebouncedLogic(AuditManager manager) {
  manager._scoreDebounceTimer?.cancel();
  manager._scoreDebounceTimer = Timer(const Duration(milliseconds: 200), () {
    _recalculateScoreLogic(manager);
    manager.notifyListeners();
  });
}
