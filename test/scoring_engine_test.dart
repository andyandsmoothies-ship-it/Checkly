// ATDD: Slice 4 — Dart Scoring Engine Unit Tests (RED phase)
//
// These tests define the behavioral contract for the Dart scoring engine.
// They will FAIL until `lib/_shared/services/scoring_engine.dart` is implemented.
//
// Test vector source: test/scoring_test_vectors.json (shared with C# tests)
// Spec source: specs_slice4_scoring_engine.md
//
// Author: Sentinel (SDET)
// Status: 🔴 RED — ScoringEngine class does not exist yet

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// --- IMPORT TARGET (will fail until implemented) ---
// This import will cause a compile error → proves RED state.
import 'package:checkly/_shared/services/scoring_engine.dart';

void main() {
  late List<Map<String, dynamic>> vectors;

  setUpAll(() {
    final file = File('test/scoring_test_vectors.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    vectors = (json['vectors'] as List).cast<Map<String, dynamic>>();
  });

  // ================================================================
  // Helper: parse test vector into ScoringEngine input
  // ================================================================
  ScoringInput parseVector(Map<String, dynamic> vector) {
    final sections = (vector['sections'] as List).map((s) {
      final criteria =
          (s['criteria'] as List?)?.map((c) {
            return CriterionInput(
              id: c['id'] as String,
              groupId: c['groupId'] as String,
              pointsWeight: (c['pointsWeight'] as num).toDouble(),
              isCcp: c['isCcp'] as bool,
              isRisk: c['isRisk'] as bool,
            );
          }).toList() ??
          [];

      final subsections =
          (s['subsections'] as List?)?.map((sub) {
            final subCriteria = (sub['criteria'] as List).map((c) {
              return CriterionInput(
                id: c['id'] as String,
                groupId: c['groupId'] as String,
                pointsWeight: (c['pointsWeight'] as num).toDouble(),
                isCcp: c['isCcp'] as bool,
                isRisk: c['isRisk'] as bool,
              );
            }).toList();

            return SubsectionInput(
              id: sub['id'] as String,
              title: sub['title'] as String,
              maxPoints: (sub['maxPoints'] as num).toDouble(),
              criteria: subCriteria,
            );
          }).toList() ??
          [];

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
      );
    }).toList();

    return ScoringInput(sections: sections, answers: answers);
  }

  // ================================================================
  // Scenario 1: Weighted audit — no faults → 100%
  // Source: SCORING_LOGIC.md §2.C
  // ================================================================
  test('V01: Weighted audit — no faults → 100%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V01_weighted_no_faults');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(100.00, 0.01));
  });

  // ================================================================
  // Scenario 2: Weighted audit — partial faults → deduction
  // Source: SCORING_LOGIC.md §2.A
  // ================================================================
  test('V02: Weighted audit — partial faults → 37.50%', () {
    final v = vectors.firstWhere(
      (v) => v['id'] == 'V02_weighted_partial_faults',
    );
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(37.50, 0.01));
  });

  // ================================================================
  // Scenario 3: CCP triggered → section score = 0%
  // Source: SCORING_LOGIC.md §3 CCP
  // ================================================================
  test('V03: CCP triggered → section A = 0%, total = 50%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V03_ccp_triggered');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(50.00, 0.01));
  });

  // ================================================================
  // Scenario 4: RISK triggered → total = 0%
  // Source: SCORING_LOGIC.md §3 RISK
  // ================================================================
  test('V04: RISK triggered → total = 0%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V04_risk_triggered');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(0.00, 0.01));
  });

  // ================================================================
  // Scenario 5: Checklist fallback (no weights) → 100 - deductions
  // Source: scoring_engine.md KI §1
  // ================================================================
  test('V05: Checklist fallback → 97%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V05_checklist_fallback');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(97.00, 0.01));
  });

  // ================================================================
  // Scenario 6: MaxDeductionPoints cap
  // Source: SCORING_LOGIC.md §2.A (subsection cap)
  // ================================================================
  test('V06: MaxDeductionPoints cap → 28.57%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V06_max_deduction_cap');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(28.57, 0.01));
  });

  // ================================================================
  // Scenario 7: non_conform value triggers RISK → 0%
  // Source: C# ScoringVerifierTests.cs lines 83-97
  // ================================================================
  test('V07: non_conform on RISK → 0%', () {
    final v = vectors.firstWhere(
      (v) => v['id'] == 'V07_non_conform_triggers_risk',
    );
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(0.00, 0.01));
  });

  // ================================================================
  // Scenario 8: conform does NOT trigger fault → 100%
  // ================================================================
  test('V08: conform → no fault → 100%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V08_conform_no_fault');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(100.00, 0.01));
  });

  // ================================================================
  // Scenario 9: Empty section skipped — no division by zero
  // Source: C# ScoringVerifier.cs line 63
  // ================================================================
  test('V09: Empty section skipped → 100%', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V09_empty_section_skipped');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(100.00, 0.01));
  });

  // ================================================================
  // Scenario 10: Multi-fault multiplier (2 × 3 = 6)
  // Source: SCORING_LOGIC.md §2.A
  // ================================================================
  test('V10: Multi-fault multiplier → 0%', () {
    final v = vectors.firstWhere(
      (v) => v['id'] == 'V10_multi_fault_multiplier',
    );
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(0.00, 0.01));
  });

  // ================================================================
  // Scenario 11: Subsection cap
  // ================================================================
  test('V11: Subsection cap limits deductions independently', () {
    final v = vectors.firstWhere((v) => v['id'] == 'V11_subsection_cap');
    final input = parseVector(v);
    final result = ScoringEngine.calculate(input);

    expect(result.totalScore, closeTo(50.00, 0.01));
  });

  // ================================================================
  // Scenario 12: Accumulation mode — 2/3 correct → 66.67%
  // ================================================================
  test('V12: Accumulation mode — 2 of 3 correct → 66.67%', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 0,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c3',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(criteriaId: 'c1', numericValue: 0), // correct
        AnswerInput(criteriaId: 'c2', numericValue: 0), // correct
        AnswerInput(criteriaId: 'c3', numericValue: 1), // fault
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(66.67, 0.01));
  });

  // ================================================================
  // Scenario 13: Accumulation + CCP fail → section = 0
  // ================================================================
  test('V13: Accumulation + CCP fail → section earned = 0', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 0,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: true,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(criteriaId: 'c1', numericValue: 1), // CCP fail
        AnswerInput(criteriaId: 'c2', numericValue: 0), // correct
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(0.00, 0.01));
    expect(result.sectionScores['s1']!.hasCcpFailure, true);
  });

  // ================================================================
  // Scenario 14: Checklist mode — 4/5 correct → 80%
  // ================================================================
  test('V14: Checklist mode — raw deduction → 80%', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 0,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 4,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 4,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c3',
              groupId: 's1',
              pointsWeight: 4,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c4',
              groupId: 's1',
              pointsWeight: 4,
              isCcp: false,
              isRisk: false,
            ),
            CriterionInput(
              id: 'c5',
              groupId: 's1',
              pointsWeight: 4,
              isCcp: false,
              isRisk: false,
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(criteriaId: 'c1', numericValue: 0),
        AnswerInput(criteriaId: 'c2', numericValue: 0),
        AnswerInput(criteriaId: 'c3', numericValue: 0),
        AnswerInput(criteriaId: 'c4', numericValue: 0),
        AnswerInput(
          criteriaId: 'c5',
          numericValue: 5,
        ), // 5 faults × 4 pts = 20 deduction
      ],
      scoringMode: ScoringMode.checklist,
    );
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(80.00, 0.01));
  });

  // ================================================================
  // Scenario 15: Backward compat — no scoringMode → defaults to penalty
  // ================================================================
  test('V15: No scoringMode defaults to penalty (backward compat)', () {
    // Uses V01 vectors which are penalty mode — same as default
    final v = vectors.firstWhere((v) => v['id'] == 'V01_weighted_no_faults');
    final input = parseVector(v);
    // parseVector does NOT set scoringMode, so it defaults to penalty
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(100.00, 0.01));
  });

  // ================================================================
  // Scenario 16: Accumulation + Scale partial credit → 75%
  // ================================================================
  test('V16: Accumulation + Scale partial credit → 75%', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 100,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
              inputType: 'scale',
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
              inputType: 'scale',
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(criteriaId: 'c1', numericValue: 5, value: 'Good'),
        AnswerInput(criteriaId: 'c2', numericValue: 10, value: 'Excellent'),
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    // Earned 5 + 10 = 15 out of possible 10 + 10 = 20 → 75%
    expect(result.totalScore, closeTo(75.00, 0.01));
  });

  // ================================================================
  // Scenario 17: Scale + is_risk with passing score → RISK NOT triggered
  // Bug fix: numericValue > 0 on scale is earned points, not faults
  // ================================================================
  test('V17: Scale + is_risk with passing score → RISK NOT triggered', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 100,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: true, // RISK criterion
              inputType: 'scale',
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
              inputType: 'scale',
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(
          criteriaId: 'c1',
          numericValue: 7,
        ), // Good score → NOT a fault
        AnswerInput(criteriaId: 'c2', numericValue: 10),
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    // 7 + 10 = 17 out of 20 = 85%, RISK should NOT trigger
    expect(result.totalScore, closeTo(85.00, 0.01));
    expect(result.hasRiskFailure, false);
  });

  // ================================================================
  // Scenario 18: Scale + is_risk with zero score → RISK triggered → 0%
  // ================================================================
  test('V18: Scale + is_risk with zero score → RISK triggered → 0%', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 100,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: true, // RISK criterion
              inputType: 'scale',
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
              inputType: 'scale',
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(
          criteriaId: 'c1',
          numericValue: 0,
        ), // Zero score → fault → RISK
        AnswerInput(criteriaId: 'c2', numericValue: 10),
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(0.00, 0.01));
    expect(result.hasRiskFailure, true);
  });

  // ================================================================
  // Scenario 19: Pass_fail + is_risk + Non-Conform → RISK triggered (regression)
  // ================================================================
  test('V19: Pass_fail + is_risk + Non-Conform → RISK triggered → 0%', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 0,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: true, // RISK criterion
              inputType: 'pass_fail',
            ),
            CriterionInput(
              id: 'c2',
              groupId: 's1',
              pointsWeight: 10,
              isCcp: false,
              isRisk: false,
              inputType: 'pass_fail',
            ),
          ],
        ),
      ],
      answers: [
        AnswerInput(criteriaId: 'c1', value: 'non_conform'), // RISK fail
        AnswerInput(criteriaId: 'c2', value: 'conform'),
      ],
      scoringMode: ScoringMode.accumulation,
    );
    final result = ScoringEngine.calculate(input);
    expect(result.totalScore, closeTo(0.00, 0.01));
    expect(result.hasRiskFailure, true);
  });
}
