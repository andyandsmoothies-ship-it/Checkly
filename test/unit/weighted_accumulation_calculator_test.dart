// TDD: Slice 1 — Weighted Accumulation Calculator Unit Tests (RED phase)
//
// These tests define the behavioral contract for the new Weighted Accumulation Calculator.
// Focus: State/Output verification of the scoring math under various conditions.
//
// Author: Sentinel (QA Agent / SDET)
// Source Plan: docs/features/accumulation-weighted/implementation_plan_slice1_20260530_191300.md

import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/services/scoring_engine.dart';
import 'package:checkly/_shared/services/scoring_mode.dart';
import 'package:checkly/_shared/services/criterion_input.dart';
import 'package:checkly/_shared/services/section_input.dart';
import 'package:checkly/_shared/services/answer_input.dart';
import 'package:checkly/_shared/services/scoring_input.dart';
import 'package:checkly/features/audit/services/scoring_input_mapper.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/features/audit/model/audit_answer.dart';

void main() {
  group('WeightedAccumulationCalculator Specs (TC-01 to TC-05)', () {
    // TC-01: Happy Path — Two sections with weights 60/40.
    // Section A (weight 60): 8/10 points earned.
    // Section B (weight 40): 5/10 points earned.
    // Expected math: ((8/10 * 60) + (5/10 * 40)) / (60 + 40) * 100 = (48 + 20) / 100 * 100 = 68.0%
    test('TC-01: Happy Path — Two sections, weighted score calculated correctly', () {
      final input = ScoringInput(
        scoringMode: ScoringMode.accumulation,
        isWeighted: true, // Note: This will initially fail to compile as the field is missing
        sections: [
          SectionInput(
            id: 'sec-a',
            weight: 60.0,
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 'sec-a',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'scale',
              ),
            ],
            subsections: [],
          ),
          SectionInput(
            id: 'sec-b',
            weight: 40.0,
            criteria: [
              CriterionInput(
                id: 'c2',
                groupId: 'sec-b',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'scale',
              ),
            ],
            subsections: [],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 8.0, value: null),
          AnswerInput(criteriaId: 'c2', numericValue: 5.0, value: null),
        ],
      );

      final result = ScoringEngine.calculate(input);
      expect(result.totalScore, closeTo(68.0, 0.01));
      expect(result.hasRiskFailure, isFalse);

      final secAScore = result.sectionScores['sec-a'];
      expect(secAScore, isNotNull);
      expect(secAScore!.maxPoints, 10.0);
      expect(secAScore.score, 8.0);
      expect(secAScore.deductions, 2.0);

      final secBScore = result.sectionScores['sec-b'];
      expect(secBScore, isNotNull);
      expect(secBScore!.maxPoints, 10.0);
      expect(secBScore.score, 5.0);
      expect(secBScore.deductions, 5.0);
    });

    // TC-02: Perfect Score
    // Section A (weight 70): 10/10 points.
    // Section B (weight 30): 10/10 points.
    // Expected math: ((10/10 * 70) + (10/10 * 30)) / 100 * 100 = 100.0%
    test('TC-02: Perfect Score — Earns 100%', () {
      final input = ScoringInput(
        scoringMode: ScoringMode.accumulation,
        isWeighted: true,
        sections: [
          SectionInput(
            id: 'sec-a',
            weight: 70.0,
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 'sec-a',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'pass_fail',
              ),
            ],
            subsections: [],
          ),
          SectionInput(
            id: 'sec-b',
            weight: 30.0,
            criteria: [
              CriterionInput(
                id: 'c2',
                groupId: 'sec-b',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'pass_fail',
              ),
            ],
            subsections: [],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 0.0, value: 'pass'),
          AnswerInput(criteriaId: 'c2', numericValue: 0.0, value: 'pass'),
        ],
      );

      final result = ScoringEngine.calculate(input);
      expect(result.totalScore, closeTo(100.0, 0.01));
    });

    // TC-03: CCP Triggered — Section Zeroed but Weight Counts
    // Section A (weight 60): earns 10 but triggers CCP fault. Earned is zeroed.
    // Section B (weight 40): earns 5/10.
    // Expected math: ((0 * 60) + (5/10 * 40)) / (60 + 40) * 100 = (0 + 20) / 100 * 100 = 20.0%
    test('TC-03: CCP Triggered — Section score zeroed but weight still counts in total weight', () {
      final input = ScoringInput(
        scoringMode: ScoringMode.accumulation,
        isWeighted: true,
        sections: [
          SectionInput(
            id: 'sec-a',
            weight: 60.0,
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 'sec-a',
                pointsWeight: 10.0,
                isCcp: true, // CCP enabled
                isRisk: false,
                inputType: 'pass_fail',
              ),
            ],
            subsections: [],
          ),
          SectionInput(
            id: 'sec-b',
            weight: 40.0,
            criteria: [
              CriterionInput(
                id: 'c2',
                groupId: 'sec-b',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'scale',
              ),
            ],
            subsections: [],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 1.0, value: 'non_conform', isCcp: true), // Trigger CCP
          AnswerInput(criteriaId: 'c2', numericValue: 5.0, value: null),
        ],
      );

      final result = ScoringEngine.calculate(input);
      expect(result.totalScore, closeTo(20.0, 0.01));

      final secAScore = result.sectionScores['sec-a'];
      expect(secAScore, isNotNull);
      expect(secAScore!.hasCcpFailure, isTrue);
      expect(secAScore.score, 0.0);
    });

    // TC-04: Risk Failure — Total Score Forced to 0
    // If hasGlobalRisk or any answered risk is triggered, final score is immediately 0.
    test('TC-04: Risk Failure — Answer risk or global risk forces final score to 0', () {
      final input = ScoringInput(
        scoringMode: ScoringMode.accumulation,
        isWeighted: true,
        sections: [
          SectionInput(
            id: 'sec-a',
            weight: 60.0,
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 'sec-a',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: true, // Risk enabled
                inputType: 'pass_fail',
              ),
            ],
            subsections: [],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 1.0, value: 'non_conform', isRisk: true),
        ],
      );

      final result = ScoringEngine.calculate(input);
      expect(result.totalScore, 0.0);
      expect(result.hasRiskFailure, isTrue);
    });

    // TC-05: Zero Section Weights — Falls Back to Unweighted Accumulation
    // All weights are 0. Expect unweighted score: (8 + 5) / (10 + 10) * 100 = 65.0%
    test('TC-05: Zero Section Weights — Falls back to unweighted calculation', () {
      final input = ScoringInput(
        scoringMode: ScoringMode.accumulation,
        isWeighted: true,
        sections: [
          SectionInput(
            id: 'sec-a',
            weight: 0.0,
            criteria: [
              CriterionInput(
                id: 'c1',
                groupId: 'sec-a',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'scale',
              ),
            ],
            subsections: [],
          ),
          SectionInput(
            id: 'sec-b',
            weight: 0.0,
            criteria: [
              CriterionInput(
                id: 'c2',
                groupId: 'sec-b',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                inputType: 'scale',
              ),
            ],
            subsections: [],
          ),
        ],
        answers: [
          AnswerInput(criteriaId: 'c1', numericValue: 8.0, value: null),
          AnswerInput(criteriaId: 'c2', numericValue: 5.0, value: null),
        ],
      );

      final result = ScoringEngine.calculate(input);
      expect(result.totalScore, closeTo(65.0, 0.01));
    });
  });

  group('ScoringInputMapper & Backward Compatibility Specs (TC-06 to TC-07)', () {
    // TC-06: ScoringInputMapper — Passes isWeighted for 'up' direction
    test('TC-06: ScoringInputMapper — Maps scoreDirection: up and isWeighted: true successfully', () {
      final template = TemplateTreeDto(
        id: 'tpl-1',
        title: 'Accumulation Weighted Template',
        type: 'audit',
        version: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        scoringLogicConfig: '{"scoreDirection":"up","isWeighted":true}',
        groups: [
          GroupDto(
            id: 'sec-a',
            title: 'Section A',
            orderIndex: 0,
            weight: 60.0,
            children: [],
            criteria: [
              CriterionDto(
                id: 'c1',
                label: 'Question 1',
                inputType: 'scale',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                orderIndex: 0,
              ),
            ],
          ),
        ],
      );

      final answers = {
        'c1': AuditAnswer(criteriaId: 'c1', numericValue: 8.0),
      };

      final input = ScoringInputMapper.fromTemplate(template, answers);

      expect(input.scoringMode, ScoringMode.accumulation);
      expect(input.isWeighted, isTrue); // Will fail compilation initially
    });

    // TC-07: Backward Compat — Old Templates with No isWeighted Still Use Unweighted Accumulation
    test('TC-07: Backward Compat — Old template with scoreDirection: up defaults isWeighted to false', () {
      final template = TemplateTreeDto(
        id: 'tpl-2',
        title: 'Legacy Accumulation Template',
        type: 'audit',
        version: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        scoringLogicConfig: '{"scoreDirection":"up"}', // No isWeighted key
        groups: [
          GroupDto(
            id: 'sec-a',
            title: 'Section A',
            orderIndex: 0,
            children: [],
            criteria: [
              CriterionDto(
                id: 'c1',
                label: 'Question 1',
                inputType: 'scale',
                pointsWeight: 10.0,
                isCcp: false,
                isRisk: false,
                orderIndex: 0,
              ),
            ],
          ),
        ],
      );

      final answers = {
        'c1': AuditAnswer(criteriaId: 'c1', numericValue: 8.0),
      };

      final input = ScoringInputMapper.fromTemplate(template, answers);

      expect(input.scoringMode, ScoringMode.accumulation);
      expect(input.isWeighted, isFalse); // Will fail compilation initially
    });
  });
}
