import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../_shared/services/answer_input.dart';
import '../../../_shared/services/criterion_input.dart';
import '../../../_shared/services/scoring_input.dart';
import '../../../_shared/services/scoring_mode.dart';
import '../../../_shared/services/section_input.dart';
import '../../../_shared/services/subsection_input.dart';
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
    Map<String, AuditAnswer> answers, {
    bool hasGlobalRisk = false,
  }) {
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
          maxDeductionPoints: c.maxDeductionPoints,
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
            maxDeductionPoints: c.maxDeductionPoints,
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
          if (numFaults == null && a.value?.toLowerCase() == 'non_conform') {
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
      hasGlobalRisk: hasGlobalRisk,
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
      final scoreDirection = config['scoreDirection'] as String?;
      final isWeighted = config['isWeighted'] as bool? ?? false;

      if (scoreDirection != null) {
        if (scoreDirection == 'none') return ScoringMode.survey;
        if (scoreDirection == 'up') return ScoringMode.accumulation;
        if (scoreDirection == 'down') {
          return isWeighted ? ScoringMode.penalty : ScoringMode.checklist;
        }
      }

      // Fallback: legacy scoringMode key (for old template snapshots)
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

  // ── Template feature flags ────────────────────────────────────────────────

  /// Returns true if the template requires all criteria to be confirmed before submission.
  static bool isConfirmRequired(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return false;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      // Read from top-level (Flutter) or features map (legacy)
      if (config['confirmCorrect'] == true) return true;
      final features = config['features'] as Map<String, dynamic>?;
      return features?['confirm_required'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if CCP (Critical Control Point) tracking is enabled for this template.
  static bool isCcpEnabled(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return true;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      if (config.containsKey('ccpOverride')) {
        return config['ccpOverride'] == true;
      }
      final features = config['features'] as Map<String, dynamic>?;
      if (features != null && features.containsKey('ccp_enabled')) {
        return features['ccp_enabled'] == true;
      }
      return true; // default true if not specified
    } catch (_) {
      return true;
    }
  }

  /// Returns true if global risk tracking is enabled for this template.
  static bool isRiskEnabled(TemplateTreeDto template) {
    if (template.scoringLogicConfig == null ||
        template.scoringLogicConfig!.isEmpty) {
      return true;
    }
    try {
      final config =
          json.decode(template.scoringLogicConfig!) as Map<String, dynamic>;
      if (config.containsKey('riskOverride')) {
        return config['riskOverride'] == true;
      }
      final features = config['features'] as Map<String, dynamic>?;
      if (features != null && features.containsKey('risk_enabled')) {
        return features['risk_enabled'] == true;
      }
      return true; // default true if not specified
    } catch (_) {
      return true;
    }
  }
}
