import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/scoring_input_mapper.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/scoring_mode.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

CriterionDto _criterion(
  String id, {
  double? weight,
  String inputType = 'numeric',
  double? maxDeductionPoints,
}) => CriterionDto(
  id: id,
  label: 'Q $id',
  description: null,
  inputType: inputType,
  pointsWeight: weight,
  isCcp: false,
  isRisk: false,
  minusImpact: null,
  maxDeductionPoints: maxDeductionPoints,
  orderIndex: 0,
  metadata: null,
);

GroupDto _group(
  String id, {
  List<CriterionDto> criteria = const [],
  List<GroupDto> children = const [],
  double? weight,
}) => GroupDto(
  id: id,
  title: 'Group $id',
  description: null,
  weight: weight,
  maxDeductionPoints: null,
  minusPerFault: null,
  orderIndex: 0,
  metadata: null,
  children: children,
  criteria: criteria,
);

TemplateTreeDto _template({
  required List<GroupDto> groups,
  String? scoringLogicConfig,
}) => TemplateTreeDto(
  id: 'tpl-1',
  title: 'Test Template',
  description: null,
  type: 'audit',
  version: 1,
  scoringLogicConfig: scoringLogicConfig,
  displayNoun: 'audit',
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  groups: groups,
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ScoringInputMapper.fromTemplate', () {
    // TC1: Flat group → SectionInput with criteria, no subsections
    test('maps flat group into SectionInput', () {
      final tmpl = _template(
        groups: [
          _group(
            'g1',
            criteria: [
              _criterion('c1', weight: 5),
              _criterion('c2', weight: 10),
            ],
            weight: 1,
          ),
        ],
      );

      final input = ScoringInputMapper.fromTemplate(tmpl, {});

      expect(input.sections.length, 1);
      final section = input.sections.first;
      expect(section.id, 'g1');
      expect(section.criteria.length, 2);
      expect(section.subsections, isEmpty);
      expect(section.criteria.first.pointsWeight, 5);
      expect(section.criteria.last.pointsWeight, 10);
    });

    // TC2: Group with children → SectionInput with SubsectionInputs
    test('maps group with child groups into SectionInput with subsections', () {
      final child = _group('sub1', criteria: [_criterion('c1', weight: 3)]);
      final tmpl = _template(
        groups: [
          _group('g1', children: [child], weight: 1),
        ],
      );

      final input = ScoringInputMapper.fromTemplate(tmpl, {});

      final section = input.sections.first;
      expect(section.subsections.length, 1);
      expect(section.subsections.first.id, 'sub1');
      expect(section.subsections.first.criteria.length, 1);
      expect(section.subsections.first.criteria.first.pointsWeight, 3);
    });

    // TC3: scoringLogicConfig JSON is parsed correctly
    test(
      'parses scoringMode and progressiveRepeat from scoringLogicConfig',
      () {
        final config =
            '{"scoringMode":"accumulation","progressiveRepeat":true}';
        final tmpl = _template(groups: [], scoringLogicConfig: config);

        final input = ScoringInputMapper.fromTemplate(tmpl, {});

        expect(input.scoringMode, ScoringMode.accumulation);
        expect(input.progressiveRepeatPenalty, isTrue);
      },
    );

    // TC4: non_conform without numericValue → numericValue defaults to 1
    test('non_conform answer without numericValue defaults to 1 fault', () {
      final tmpl = _template(
        groups: [
          _group('g1', criteria: [_criterion('c1', weight: 5)], weight: 1),
        ],
      );
      final answers = {
        'c1': AuditAnswer(criteriaId: 'c1', value: 'non_conform'),
      };

      final input = ScoringInputMapper.fromTemplate(tmpl, answers);

      final answer = input.answers.firstWhere((a) => a.criteriaId == 'c1');
      expect(answer.numericValue, 1.0);
      expect(answer.value, 'non_conform');
    });

    // TC5: Phase 1B Visual Folders maxDeductionPoints
    test('maps maxDeductionPoints from CriterionDto to CriterionInput', () {
      final tmpl = _template(
        groups: [
          _group(
            'g1',
            criteria: [_criterion('c1', weight: 5, maxDeductionPoints: 3.5)],
            weight: 1,
          ),
        ],
      );

      final input = ScoringInputMapper.fromTemplate(tmpl, {});

      final section = input.sections.first;
      expect(section.criteria.length, 1);
      expect(section.criteria.first.maxDeductionPoints, 3.5);
    });

    group('parseScoringMode (Slice 3 Redesign)', () {
      test('TC-01: down + weighted -> penalty', () {
        final config = '{"scoreDirection":"down","isWeighted":true}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.penalty);
      });

      test('TC-02: down + unweighted -> checklist', () {
        final config = '{"scoreDirection":"down","isWeighted":false}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.checklist);
      });

      test('TC-03: up -> accumulation', () {
        final config = '{"scoreDirection":"up","isWeighted":false}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.accumulation);
      });

      test('TC-04: none -> survey', () {
        final config = '{"scoreDirection":"none","isWeighted":false}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.survey);
      });

      test('TC-05: null input -> penalty default', () {
        expect(ScoringInputMapper.parseScoringMode(null), ScoringMode.penalty);
      });

      test('TC-05b: malformed JSON -> penalty default', () {
        expect(ScoringInputMapper.parseScoringMode('{ bad'), ScoringMode.penalty);
      });

      test('TC-06: legacy scoringMode key still works (accumulation)', () {
        final config = '{"scoringMode":"accumulation"}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.accumulation);
      });

      test('TC-06b: legacy scoringMode key still works (checklist)', () {
        final config = '{"scoringMode":"checklist"}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.checklist);
      });

      test('TC-07: scoreDirection present, isWeighted missing -> defaults false -> checklist', () {
        final config = '{"scoreDirection":"down"}';
        expect(ScoringInputMapper.parseScoringMode(config), ScoringMode.checklist);
      });
    });
  });
}
