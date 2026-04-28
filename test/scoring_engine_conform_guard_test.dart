// TDD: CG (Conform Guard) Tests for ScoringEngine._getDeduction()
//
// Bug: Flutter's _getDeduction() has no guard for 'conform' or 'na' answer values.
// The server's C# ScoringVerifier.GetDeduction() returns 0 for those values immediately.
// If an answer has value='conform' AND a stale non-zero numericValue (from DB or prior entry),
// Flutter computes phantom deductions that the server doesn't — causing 400 score mismatches.
//
// Fix: Add a conform/na guard at the top of _getDeduction() (before reading numericValue),
// mirroring ScoringVerifier.GetDeduction() lines 314-316.
//
// Test approach: Detroit (Classical) style — test through ScoringEngine.calculate() public API.
// Each test crafts ScoringInput so the mismatched _getDeduction() path is exercised, then
// asserts on the OBSERVABLE totalScore. No private-method access needed.
//
// Naming: Entity_Condition_ExpectedOutcome
// Author: Sentinel (SDET) | Workflow: /tdd | Date: 2026-04-16

import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/services/scoring_engine.dart';
import 'package:checkly/_shared/services/scoring_mode.dart';
import 'package:checkly/_shared/services/criterion_input.dart';
import 'package:checkly/_shared/services/section_input.dart';
import 'package:checkly/_shared/services/answer_input.dart';
import 'package:checkly/_shared/services/scoring_input.dart';

void main() {
  // ================================================================
  // CG1: conform with stale numericValue → NO phantom deduction (penalty mode)
  //
  // Scenario: 2 pass_fail criteria in a weighted section.
  //   c1: value='conform', numericValue=1 (stale) → server returns 0, Flutter must also return 0
  //   c2: value='conform', numericValue=null → 0 deduction (no fault)
  //
  // Without the guard: _getDeduction returns 1×10=10 phantom deduction for c1
  //   sectionAfter = 20 - 10 = 10, ratio = 10/20 = 0.5, score = 50%  ← WRONG
  // With the guard: both return 0, sectionAfter = 20, ratio = 1.0, score = 100% ← CORRECT
  //
  // Why RED: Line ~354 of scoring_engine.dart has no conform guard.
  // ================================================================
  test(
    'ScoringEngine_ConformWithStaleNumericValue_NoPhantomDeduction_PenaltyMode',
    () {
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
          // c1: conform answer but has a stale numericValue=1 stored in DB.
          // The guard must treat value='conform' as 0 deduction regardless of numericValue.
          AnswerInput(criteriaId: 'c1', value: 'conform', numericValue: 1),
          // c2: clean conform, no numericValue.
          AnswerInput(criteriaId: 'c2', value: 'conform'),
        ],
        scoringMode: ScoringMode.penalty,
      );

      final result = ScoringEngine.calculate(input);

      // Both criteria are conform → 0 deductions → 100%
      expect(
        result.totalScore,
        closeTo(100.00, 0.01),
        reason:
            'conform with stale numericValue should produce 0 deduction (guard missing)',
      );
    },
  );

  // ================================================================
  // CG2: na with stale numericValue=2 → NO phantom deduction (penalty mode)
  //
  // 'na' (Not Applicable) is the same as 'conform' for scoring purposes.
  // Without the guard: _getDeduction returns 2×5=10 phantom deduction → score drops.
  // With the guard: returns 0 → score = 100%.
  //
  // Why RED: _getDeduction has no 'na' check; GetDeduction() on server does (L316).
  // ================================================================
  test('ScoringEngine_NaWithStaleNumericValue_NoPhantomDeduction_PenaltyMode', () {
    final input = ScoringInput(
      sections: [
        SectionInput(
          id: 's1',
          weight: 100,
          criteria: [
            CriterionInput(
              id: 'c1',
              groupId: 's1',
              pointsWeight: 5,
              isCcp: false,
              isRisk: false,
              inputType: 'numeric',
            ),
          ],
        ),
      ],
      answers: [
        // na with stale numericValue=2.
        // Without guard: 2 × 5 = 10 phantom deduction → score = max(0, 100-10) in checklist,
        // or in weighted: after = 5-10 → clamped to 0 → ratio=0 → score=0%.
        // With guard: returns 0 → score = 100%.
        AnswerInput(criteriaId: 'c1', value: 'na', numericValue: 2),
      ],
      scoringMode: ScoringMode.penalty,
    );

    final result = ScoringEngine.calculate(input);

    // 'na' answer = not applicable = 0 deduction
    expect(
      result.totalScore,
      closeTo(100.00, 0.01),
      reason:
          'na answer must return 0 deduction regardless of stale numericValue',
    );
  });

  // ================================================================
  // CG3: conform with stale numericValue → NO phantom deduction (checklist mode)
  //
  // Checklist mode sums ALL deductions directly: score = max(0, 100 - Σdeductions).
  // 3 criteria (10pts each). c2 is conform with stale numericValue=1.
  //
  // Without guard: totalDeductions = 0 + 10 + 0 = 10 → score = max(0, 100-10) = 90% ← WRONG
  // With guard:    totalDeductions = 0 + 0  + 0 = 0  → score = 100% ← CORRECT
  //
  // Why RED: _calculateChecklist calls _getDeduction for all criteria. No conform guard.
  // ================================================================
  test(
    'ScoringEngine_ConformWithStaleNumericValue_NoPhantomDeduction_ChecklistMode',
    () {
      final input = ScoringInput(
        sections: [
          SectionInput(
            id: 's1',
            weight: 0, // weight=0 forces checklist fallback
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 's1',
                pointsWeight: 10,
                isCcp: false,
                isRisk: false,
                inputType: 'numeric',
              ),
              CriterionInput(
                id: 'c2',
                groupId: 's1',
                pointsWeight: 10,
                isCcp: false,
                isRisk: false,
                inputType: 'pass_fail',
              ),
              CriterionInput(
                id: 'c3',
                groupId: 's1',
                pointsWeight: 10,
                isCcp: false,
                isRisk: false,
                inputType: 'numeric',
              ),
            ],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 0), // no fault
          // c2: conform but stale numericValue=1 from a prior edit session
          AnswerInput(criteriaId: 'c2', value: 'conform', numericValue: 1),
          AnswerInput(criteriaId: 'c3', numericValue: 0), // no fault
        ],
        scoringMode: ScoringMode.checklist,
      );

      final result = ScoringEngine.calculate(input);

      expect(
        result.totalScore,
        closeTo(100.00, 0.01),
        reason:
            'conform with stale numericValue must not cause phantom deduction in checklist mode',
      );
    },
  );

  // ================================================================
  // CG4: non_conform without numericValue → deduction IS applied (positive path)
  //
  // This verifies the guard does NOT block real faults.
  // The mapper (scoring_input_mapper.dart L73) defaults non_conform+null → numericValue=1.
  // In these unit tests we simulate that mapped state directly.
  //
  // Setup: 2 pass_fail criteria, 1 weighted section.
  //   c1: value='non_conform', numericValue=1 (as mapper would produce)
  //   c2: value='conform', no numericValue
  //
  // Expected: c1 causes 10pt deduction. c2 causes 0. sectionAfter=10, ratio=0.5, score=50%.
  //
  // Without guard: same result (non_conform is not blocked, only conform/na are).
  // With guard: same result (guard only short-circuits conform/na, not non_conform).
  // This test must pass BOTH before and after the fix — it's a regression guard.
  // ================================================================
  test(
    'ScoringEngine_NonConformWithMappedNumericValue_DeductionApplied_PenaltyMode',
    () {
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
          // Simulates what scoring_input_mapper.dart produces:
          // non_conform with null numericValue → mapper defaults to 1.
          AnswerInput(criteriaId: 'c1', value: 'non_conform', numericValue: 1),
          AnswerInput(criteriaId: 'c2', value: 'conform'),
        ],
        scoringMode: ScoringMode.penalty,
      );

      final result = ScoringEngine.calculate(input);

      // c1: 1 fault × 10pts = 10 deduction. sectionAfter = 20-10 = 10. ratio = 0.5. score = 50%.
      expect(
        result.totalScore,
        closeTo(50.00, 0.01),
        reason:
            'real non_conform fault must still be deducted after the guard is applied',
      );
    },
  );

  // ================================================================
  // CG5: Real-world 44.44 vs 77.78 scenario (the actual production bug)
  //
  // Reproduces the exact production mismatch:
  //   Client: 44.44, Server: 77.78.
  //   3 phantom deductions from 3 'conform' answers with stale numericValue=1.
  //   2 real non_conform faults. Total criteria = 9, each 10pts, 1 weighted section.
  //
  // Without guard:
  //   total deductions = 2 (real) + 3 (phantom) = 5 × 10 = 50. score = (90-50)/90 = 44.44%
  // With guard:
  //   total deductions = 2 (real) only = 2 × 10 = 20. score = (90-20)/90 = 77.78%
  //   → matches server → no 400
  //
  // Why RED: _getDeduction has no conform guard. CG5 fails on CURRENT production code.
  // ================================================================
  test(
    'ScoringEngine_ThreePhantomConformDeductions_MatchesServerScore_77_78',
    () {
      final criteria = [
        for (int i = 1; i <= 9; i++)
          CriterionInput(
            id: 'c$i',
            groupId: 's1',
            pointsWeight: 10,
            isCcp: false,
            isRisk: false,
            inputType: 'pass_fail',
          ),
      ];

      final input = ScoringInput(
        sections: [SectionInput(id: 's1', weight: 100, criteria: criteria)],
        answers: [
          // 2 REAL non_conform faults → 20 pts deducted
          AnswerInput(criteriaId: 'c1', value: 'non_conform', numericValue: 1),
          AnswerInput(criteriaId: 'c2', value: 'non_conform', numericValue: 1),
          // 3 PHANTOM: conform answers with stale numericValue from prior entry
          AnswerInput(criteriaId: 'c3', value: 'conform', numericValue: 1),
          AnswerInput(criteriaId: 'c4', value: 'conform', numericValue: 1),
          AnswerInput(criteriaId: 'c5', value: 'conform', numericValue: 1),
          // 4 CLEAN conforms — no numericValue
          AnswerInput(criteriaId: 'c6', value: 'conform'),
          AnswerInput(criteriaId: 'c7', value: 'conform'),
          AnswerInput(criteriaId: 'c8', value: 'conform'),
          AnswerInput(criteriaId: 'c9', value: 'conform'),
        ],
        scoringMode: ScoringMode.penalty,
      );

      final result = ScoringEngine.calculate(input);

      // Must match server: (90-20)/90 = 77.78%
      // Current broken code produces: (90-50)/90 = 44.44%
      expect(
        result.totalScore,
        closeTo(77.78, 0.01),
        reason:
            'Flutter score must match server score. '
            'Phantom deductions from stale numericValue on conform answers must be zero.',
      );
    },
  );
}
