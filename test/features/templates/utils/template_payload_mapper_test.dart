import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/models/editable_criterion.dart';
import 'package:checkly/features/templates/models/editable_group.dart';
import 'package:checkly/features/templates/utils/template_payload_mapper.dart';

void main() {
  group('TemplatePayloadMapper - buildGroupsPayload', () {
    test('isEditMode: true retains group and criteria IDs', () {
      final group = EditableGroup(id: 'grp-123', title: 'Root Group');

      final criterion = EditableCriterion(
        id: 'crit-456',
        inputType: 'pass_fail',
      );
      criterion.labelCtrl.text = 'Pass Fail Crit';
      group.criteria.add(criterion);

      final payload = buildGroupsPayload(
        groups: [group],
        confirmCorrect: false,
        isEditMode: true,
      );

      expect(payload, hasLength(1));
      expect(payload[0]['id'], 'grp-123');
      expect(payload[0]['criteria'], hasLength(1));
      expect(payload[0]['criteria'][0]['id'], 'crit-456');
    });

    test('isEditMode: false omits group and criteria IDs', () {
      final group = EditableGroup(id: 'grp-123', title: 'Root Group');

      final criterion = EditableCriterion(
        id: 'crit-456',
        inputType: 'pass_fail',
      );
      criterion.labelCtrl.text = 'Pass Fail Crit';
      group.criteria.add(criterion);

      final payload = buildGroupsPayload(
        groups: [group],
        confirmCorrect: false,
        isEditMode: false,
      );

      expect(payload, hasLength(1));
      expect(payload[0].containsKey('id'), isFalse);
      expect(payload[0]['criteria'], hasLength(1));
      expect(payload[0]['criteria'][0].containsKey('id'), isFalse);
    });

    test(
      'includes weight, maxDeductionPoints, minusPerFault and metadata for groups',
      () {
        final group = EditableGroup(title: 'Root Group');
        group.weightCtrl.text = '0.75';
        group.maxPointsCtrl.text = '20.0';
        group.minusPerFaultCtrl.text = '5.0';

        final payload = buildGroupsPayload(
          groups: [group],
          confirmCorrect: false,
          isEditMode: true,
        );

        expect(payload, hasLength(1));
        expect(payload[0]['weight'], 0.75);
        expect(payload[0]['maxDeductionPoints'], 20.0);
        expect(payload[0]['minusPerFault'], 5.0);

        expect(payload[0]['metadata'], isNotNull);
        final metadataMap =
            json.decode(payload[0]['metadata'] as String)
                as Map<String, dynamic>;
        expect(metadataMap['subsection_max_points'], 20.0);
        expect(metadataMap['minus_per_fault'], 5.0);
      },
    );

    test('omits group metadata when maxPoints and minusPerFault are empty', () {
      final group = EditableGroup(title: 'Root Group');
      final payload = buildGroupsPayload(
        groups: [group],
        confirmCorrect: false,
        isEditMode: true,
      );

      expect(payload, hasLength(1));
      expect(payload[0]['metadata'], isNull);
    });

    test(
      'excludes pointsWeight, minusImpact, maxDeductionPoints for text/choice type criteria at all levels',
      () {
        final group = EditableGroup(title: 'Root Group');

        final textCrit = EditableCriterion(inputType: 'text');
        textCrit.labelCtrl.text = 'Text';
        textCrit.pointsCtrl.text = '10.0';
        textCrit.minusImpactCtrl.text = '2.0';
        textCrit.maxDeductionCtrl.text = '5.0';

        final choiceCrit = EditableCriterion(inputType: 'single_choice');
        choiceCrit.labelCtrl.text = 'Choice';
        choiceCrit.pointsCtrl.text = '15.0';
        choiceCrit.minusImpactCtrl.text = '3.0';
        choiceCrit.maxDeductionCtrl.text = '6.0';
        choiceCrit.choiceOptions = ['Yes', 'No'];

        group.criteria.addAll([textCrit, choiceCrit]);

        final payload = buildGroupsPayload(
          groups: [group],
          confirmCorrect: false,
          isEditMode: true,
        );

        final criteria = payload[0]['criteria'] as List;
        expect(criteria, hasLength(2));

        final textPayload = criteria[0] as Map<String, dynamic>;
        expect(textPayload.containsKey('pointsWeight'), isFalse);
        expect(textPayload.containsKey('minusImpact'), isFalse);
        expect(textPayload.containsKey('maxDeductionPoints'), isFalse);

        final choicePayload = criteria[1] as Map<String, dynamic>;
        expect(choicePayload.containsKey('pointsWeight'), isFalse);
        expect(choicePayload.containsKey('minusImpact'), isFalse);
        expect(choicePayload.containsKey('maxDeductionPoints'), isFalse);
      },
    );

    test(
      'includes pointsWeight, minusImpact, maxDeductionPoints for standard input types when populated',
      () {
        final group = EditableGroup(title: 'Root Group');
        final crit = EditableCriterion(inputType: 'pass_fail');
        crit.labelCtrl.text = 'Standard';
        crit.pointsCtrl.text = '10.0';
        crit.minusImpactCtrl.text = '2.0';
        crit.maxDeductionCtrl.text = '5.0';
        group.criteria.add(crit);

        final payload = buildGroupsPayload(
          groups: [group],
          confirmCorrect: false,
          isEditMode: true,
        );

        final cPayload = payload[0]['criteria'][0] as Map<String, dynamic>;
        expect(cPayload['pointsWeight'], 10.0);
        expect(cPayload['minusImpact'], 2.0);
        expect(cPayload['maxDeductionPoints'], 5.0);
      },
    );

    test(
      'encodes isRequired, options, scaleOptions inside metadata for criteria',
      () {
        final group = EditableGroup(title: 'Root');

        final critScale = EditableCriterion(
          inputType: 'scale',
          scaleOptions: [
            {'score': 1.0, 'label': 'One'},
            {'score': 2.0, 'label': 'Two'},
            {'score': 3.0, 'label': 'Three'},
          ],
        );
        critScale.labelCtrl.text = 'Scale';
        critScale.isRequired = true;

        final critChoice = EditableCriterion(inputType: 'single_choice');
        critChoice.labelCtrl.text = 'Choice';
        critChoice.choiceOptions = ['A', 'B'];

        group.criteria.addAll([critScale, critChoice]);

        final payload = buildGroupsPayload(
          groups: [group],
          confirmCorrect: false,
          isEditMode: true,
        );

        final criteria = payload[0]['criteria'] as List;

        final scaleMeta =
            json.decode(criteria[0]['metadata'] as String)
                as Map<String, dynamic>;
        expect(scaleMeta['isRequired'], isTrue);
        expect(scaleMeta['scaleOptions'], [
          {'score': 1.0, 'label': 'One'},
          {'score': 2.0, 'label': 'Two'},
          {'score': 3.0, 'label': 'Three'},
        ]);

        final choiceMeta =
            json.decode(criteria[1]['metadata'] as String)
                as Map<String, dynamic>;
        expect(choiceMeta['options'], ['A', 'B']);
      },
    );

    test('confirmCorrect=true forces isRequired=true in criteria metadata', () {
      final group = EditableGroup(title: 'Root');
      final crit = EditableCriterion(inputType: 'pass_fail');
      crit.labelCtrl.text = 'Standard';
      crit.isRequired = false;
      group.criteria.add(crit);

      final payload = buildGroupsPayload(
        groups: [group],
        confirmCorrect: true,
        isEditMode: true,
      );

      final criteria = payload[0]['criteria'] as List;
      final meta =
          json.decode(criteria[0]['metadata'] as String)
              as Map<String, dynamic>;
      expect(meta['isRequired'], isTrue);
    });

    test('round-trips isCcp and isRisk for criteria', () {
      final group = EditableGroup(title: 'Root');
      final crit = EditableCriterion(inputType: 'pass_fail');
      crit.labelCtrl.text = 'Ccp Risk';
      crit.isCcp = true;
      crit.isRisk = true;
      group.criteria.add(crit);

      final payload = buildGroupsPayload(
        groups: [group],
        confirmCorrect: false,
        isEditMode: true,
      );

      final cPayload = payload[0]['criteria'][0] as Map<String, dynamic>;
      expect(cPayload['isCcp'], isTrue);
      expect(cPayload['isRisk'], isTrue);
    });
  });

  group('TemplatePayloadMapper - buildScoringLogicConfig', () {
    test('correctly serializes the scoring logic configuration', () {
      final jsonStr = buildScoringLogicConfig(
        scoreDirection: 'down',
        isWeighted: true,
        ccpOverride: true,
        riskOverride: false,
        weightedDensity: true,
        progressiveRepeat: false,
        confirmCorrect: true,
        deadlineDays: '10',
        reminderDays: '3',
      );

      final config = json.decode(jsonStr) as Map<String, dynamic>;
      expect(config['scoreDirection'], 'down');
      expect(config['isWeighted'], isTrue);
      expect(config['scoringMode'], 'penalty');
      expect(config['ccpOverride'], isTrue);
      expect(config['riskOverride'], isFalse);
      expect(config['weightedDensity'], isTrue);
      expect(config['progressiveRepeat'], isFalse);
      expect(config['confirmCorrect'], isTrue);
      expect(config['deadlineDays'], 10);
      expect(config['reminderDays'], 3);
    });

    test(
      'defaults invalid deadline and reminder days to standard fallbacks',
      () {
        final jsonStr = buildScoringLogicConfig(
          scoreDirection: 'down',
          isWeighted: true,
          ccpOverride: false,
          riskOverride: false,
          weightedDensity: false,
          progressiveRepeat: false,
          confirmCorrect: false,
          deadlineDays: 'invalid',
          reminderDays: '',
        );

        final config = json.decode(jsonStr) as Map<String, dynamic>;
        expect(config['deadlineDays'], 7);
        expect(config['reminderDays'], 2);
      },
    );
  });
}
