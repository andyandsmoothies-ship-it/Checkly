import '../models/editable_group.dart';
import '../models/lint_result.dart';

class DartTemplateLinter {
  static LintResult lint({
    required List<EditableGroup> sections,
    required String scoringMode,
    required String templateType,
    required bool progressiveRepeat,
  }) {
    final List<LintIssue> errors = [];
    final List<LintIssue> warnings = [];

    // 1. EmptyStructureCheck
    if (sections.isEmpty) {
      errors.add(
        LintIssue(
          ruleId: 'EmptyStructureCheck',
          message: 'The template must contain at least one group or section.',
          severity: 'Error',
        ),
      );
      return LintResult(errors: errors, warnings: warnings);
    }

    // Traverse all elements helper
    final List<String> allIds = [];

    void collectIds(EditableGroup group) {
      allIds.add(group.id);
      for (final c in group.criteria) {
        allIds.add(c.id);
      }
      for (final sub in group.subSections) {
        collectIds(sub);
      }
    }

    for (final sec in sections) {
      collectIds(sec);
    }

    // 4. DuplicateIdCheck
    final Set<String> uniqueIds = {};
    bool hasDuplicate = false;
    for (final id in allIds) {
      if (id.isNotEmpty && !uniqueIds.add(id)) {
        hasDuplicate = true;
      }
    }
    if (hasDuplicate) {
      errors.add(
        LintIssue(
          ruleId: 'DuplicateIdCheck',
          message: 'Duplicate element IDs detected.',
          severity: 'Error',
        ),
      );
    }

    // Helper recursive depth check
    int getDepth(EditableGroup group, int currentDepth) {
      if (group.subSections.isEmpty) {
        return currentDepth;
      }
      int maxSubDepth = currentDepth;
      for (final sub in group.subSections) {
        final d = getDepth(sub, currentDepth + 1);
        if (d > maxSubDepth) {
          maxSubDepth = d;
        }
      }
      return maxSubDepth;
    }

    // 5. MaxNestingDepthExceeded
    bool depthExceeded = false;
    for (final sec in sections) {
      if (getDepth(sec, 1) > 2) {
        depthExceeded = true;
      }
    }
    if (depthExceeded) {
      errors.add(
        LintIssue(
          ruleId: 'MaxNestingDepthExceeded',
          message:
              'Template groups cannot be nested more than 2 levels deep (Group -> Child Group).',
          severity: 'Error',
        ),
      );
    }

    // 3. PenaltyModeGroupSum
    if (scoringMode == 'penalty' && templateType != 'survey') {
      final hasAnyWeight = sections.any(
        (s) => s.weightCtrl.text.trim().isNotEmpty,
      );
      if (hasAnyWeight) {
        double total = 0.0;
        for (final s in sections) {
          total += double.tryParse(s.weightCtrl.text) ?? 0.0;
        }
        if (total != 100.0) {
          errors.add(
            LintIssue(
              ruleId: 'PenaltyModeGroupSum',
              message:
                  'The sum of all section weights must equal exactly 100 in penalty mode.',
              severity: 'Error',
            ),
          );
        }
      }
    }

    // Recursive logic for individual groups and criteria checks
    void checkGroup(EditableGroup group) {
      // 2. EmptySectionName
      if (group.titleCtrl.text.trim().isEmpty) {
        errors.add(
          LintIssue(
            ruleId: 'EmptySectionName',
            message:
                'Section title cannot be empty or contain only whitespace.',
            targetId: group.id,
            severity: 'Error',
          ),
        );
      }

      // 6. MixedAuditWarning
      bool hasScored = false;
      bool hasUnscored = false;
      for (final c in group.criteria) {
        final pts = double.tryParse(c.pointsCtrl.text) ?? 0.0;
        if (pts > 0) {
          hasScored = true;
        } else {
          hasUnscored = true;
        }
      }
      if (hasScored && hasUnscored) {
        warnings.add(
          LintIssue(
            ruleId: 'MixedAuditWarning',
            message:
                'Mixed scored and unscored criteria found in the same section.',
            targetId: group.id,
            severity: 'Warning',
          ),
        );
      }

      // Check criteria
      for (final c in group.criteria) {
        // 7. SilentRiskInSurvey
        if (templateType == 'survey' && c.isRisk) {
          warnings.add(
            LintIssue(
              ruleId: 'SilentRiskInSurvey',
              message:
                  'Risk question marked with weight/points is present in a survey template.',
              targetId: c.id,
              severity: 'Warning',
            ),
          );
        }

        // 8. ProgressiveZeroImpact
        if (progressiveRepeat) {
          final impact = double.tryParse(c.minusImpactCtrl.text) ?? 0.0;
          if (impact <= 0.0) {
            warnings.add(
              LintIssue(
                ruleId: 'ProgressiveZeroImpact',
                message:
                    'Progressive repeat penalty is enabled but deducting minus impact is 0.',
                targetId: c.id,
                severity: 'Warning',
              ),
            );
          }
        }
      }

      // Recurse sub-sections
      for (final sub in group.subSections) {
        checkGroup(sub);
      }
    }

    for (final sec in sections) {
      checkGroup(sec);
    }

    return LintResult(errors: errors, warnings: warnings);
  }
}
