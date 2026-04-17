// ATDD: Slice 4 — Dart Scoring Engine Unit Tests (RED phase)
//
// These tests define the behavioral contract for the Dart scoring engine.
// Test vector source: test/scoring_test_vectors.json (shared with C# tests)
// Spec source: specs_slice4_scoring_engine.md
//
// Author: Sentinel (SDET)

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/services/scoring_engine.dart';
import 'package:checkly/_shared/services/scoring_models.dart';

void main() {
  late List<Map<String, dynamic>> vectors;

  setUpAll(() {
    final file = File('test/scoring_test_vectors.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    vectors = (json['vectors'] as List).cast<Map<String, dynamic>>();
  });

  ScoringInput parseVector(Map<String, dynamic> vector) {
    final scoringModeStr = vector['scoringMode'] as String? ?? 'penalty';
    final scoringMode = ScoringMode.values.firstWhere(
      (m) => m.name == scoringModeStr, orElse: () => ScoringMode.penalty);
    final progressiveRepeat = vector['progressiveRepeatPenalty'] as bool? ?? false;

    final sections = (vector['sections'] as List).map((s) {
      final criteria =
          (s['criteria'] as List?)?.map((c) {
            return CriterionInput(
              id: c['id'] as String,
              groupId: c['groupId'] as String,
              pointsWeight: c['pointsWeight'] != null ? (c['pointsWeight'] as num).toDouble() : 0.0,
              isCcp: c['isCcp'] as bool,
              isRisk: c['isRisk'] as bool,
              minusImpact: c['minusImpact'] != null ? (c['minusImpact'] as num).toDouble() : null,
              inputType: c['inputType'] as String? ?? 'numeric',
            );
          }).toList() ?? [];

      final subsections =
          (s['subsections'] as List?)?.map((sub) {
            final subCriteria = (sub['criteria'] as List).map((c) {
              return CriterionInput(
                id: c['id'] as String,
                groupId: c['groupId'] as String,
                pointsWeight: c['pointsWeight'] != null ? (c['pointsWeight'] as num).toDouble() : 0.0,
                isCcp: c['isCcp'] as bool,
                isRisk: c['isRisk'] as bool,
                minusImpact: c['minusImpact'] != null ? (c['minusImpact'] as num).toDouble() : null,
                inputType: c['inputType'] as String? ?? 'numeric',
              );
            }).toList();

            return SubsectionInput(
              id: sub['id'] as String,
              title: sub['title'] as String,
              maxPoints: (sub['maxPoints'] as num).toDouble(),
              criteria: subCriteria,
            );
          }).toList() ?? [];

      return SectionInput(
        id: s['id'] as String,
        weight: (s['weight'] as num).toDouble(),
        maxDeductionPoints: s['maxDeductionPoints'] != null
            ? (s['maxDeductionPoints'] as num).toDouble()
            : null,
        subsections: subsections,
        criteria: criteria,
      );
    }).toList();

    final answers = (vector['answers'] as List).map((a) {
      return AnswerInput(
        criteriaId: a['criteriaId'] as String,
        numericValue: a['numericValue'] != null
            ? (a['numericValue'] as num).toDouble()
            : null,
        value: a['value'] as String?,
        repeatedFaults: a['repeatedFaults'] as int? ?? 0,
        isRisk: a['isExplicitRiskOverride'] as bool? ?? false,
      );
    }).toList();

    return ScoringInput(sections: sections, answers: answers, scoringMode: scoringMode, progressiveRepeatPenalty: progressiveRepeat);
  }

  test('Run all vectors from JSON', () {
    for (var v in vectors) {
      final isPurityGate = v['isPurityGateTriggered'] as bool? ?? false;
      final expectedError = v['expectedError'] as String?;
      final id = v['id'];

      if (expectedError != null) {
        expect(() => ScoringEngine.calculate(parseVector(v)), throwsA(anything), reason: '$id should throw $expectedError');
        continue;
      }

      final result = ScoringEngine.calculate(parseVector(v));
      if (isPurityGate) {
        expect(result.totalScore, isNull, reason: '$id: purity gate should suppress score');
      } else {
        expect(result.totalScore, closeTo((v['expectedScore'] as num).toDouble(), 0.01), reason: '$id failed score check');
      }
    }
  });
}
