import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../_shared/services/scoring_models.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';

/// Pure static mapper: converts a [TemplateTreeDto] + [AuditAnswer] map
/// into a [ScoringInput] ready for [ScoringEngine.calculate()].
///
/// Extracted from [AuditManager] to eliminate duplicate scoring logic.
/// Contains zero side-effects and no Flutter state. Safe to unit-test in isolation.
class ScoringInputMapper {
  ScoringInputMapper._();

  /// Builds a [ScoringInput] from the current template and answers.
  ///
  /// - Handles flat criteria (top-level on a group) and subsections (child groups).
  /// - Applies the `non_conform` → `numericValue = 1` default.
  /// - Reads `scoringMode` and `progressiveRepeat` from `scoringLogicConfig` JSON.
  static ScoringInput fromTemplate(
    TemplateTreeDto template,
    Map<String, AuditAnswer> answers,
  ) {
    final sections = template.groups.map((g) {
      // Top-level (flat) criteria on this section
      final flatCriteria = g.criteria.map((c) {
        return CriterionInput(
          id: c.id,
          groupId: g.id,
          pointsWeight: c.pointsWeight ?? 0,
          isCcp: c.isCcp,
          isRisk: c.isRisk,
          inputType: c.inputType,
          minusImpact: c.minusImpact,
        );
      }).toList();

      // Subsections (child groups)
      final subsections = g.children.map((sub) {
        final subCriteria = _flattenCriteria(sub).map((c) {
          return CriterionInput(
            id: c.id,
            groupId: sub.id,
            pointsWeight: c.pointsWeight ?? 0,
            isCcp: c.isCcp,
            isRisk: c.isRisk,
            inputType: c.inputType,
            minusImpact: c.minusImpact,
          );
        }).toList();

        return SubsectionInput(
          id: sub.id,
          title: sub.title,
          maxPoints: sub.maxDeductionPoints ?? 0,
          criteria: subCriteria,
        );
      }).toList();

      return SectionInput(
        id: g.id,
        weight: g.weight ?? 0,
        maxDeductionPoints: g.maxDeductionPoints,
        subsections: subsections,
        criteria: flatCriteria,
      );
    }).toList();

    final scoringAnswers = answers.values
        .map((a) {
          // non_conform without an explicit numeric value defaults to 1 fault.
          double? numFaults = a.numericValue;
          if (numFaults == null && a.value == 'non_conform') {
            numFaults = 1;
          }
          return AnswerInput(
            criteriaId: a.criteriaId,
            numericValue: numFaults,
            value: a.value,
            repeatedFaults: a.repeatedFaultCount,
            isCcp: a.isCcp,
            isRisk: a.isRisk,
          );
        })
        .where(
          (a) =>
              a.numericValue != null || a.value != null || a.isCcp || a.isRisk,
        )
        .toList();

    return ScoringInput(
      sections: sections,
      answers: scoringAnswers,
      scoringMode: parseScoringMode(template.scoringLogicConfig),
      progressiveRepeatPenalty: _parseBoolConfig(
        template.scoringLogicConfig,
        'progressiveRepeat',
      ),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Recursively flattens all criteria in a group and its children.
  static List<CriterionDto> _flattenCriteria(GroupDto group) {
    final result = <CriterionDto>[...group.criteria];
    for (final child in group.children) {
      result.addAll(_flattenCriteria(child));
    }
    return result;
  }

  /// Reads [scoringMode] from the template's `scoringLogicConfig` JSON.
  static ScoringMode parseScoringMode(String? configJson) {
    if (configJson == null || configJson.isEmpty) return ScoringMode.penalty;
    try {
      final config = json.decode(configJson) as Map<String, dynamic>;
      final mode = config['scoringMode'] as String?;
      if (mode == 'accumulation') return ScoringMode.accumulation;
      if (mode == 'checklist') return ScoringMode.checklist;
      if (mode == 'survey') return ScoringMode.survey;
    } catch (e) {
      debugPrint('ScoringInputMapper: parse scoringMode: $e');
    }
    return ScoringMode.penalty;
  }

  /// Reads a boolean field from the `scoringLogicConfig` JSON.
  static bool _parseBoolConfig(String? configJson, String key) {
    if (configJson == null || configJson.isEmpty) return false;
    try {
      final config = json.decode(configJson) as Map<String, dynamic>;
      return config[key] == true;
    } catch (e) {
      debugPrint('ScoringInputMapper: parse config[$key]: $e');
    }
    return false;
  }

}
