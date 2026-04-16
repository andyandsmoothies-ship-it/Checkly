import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/audit/services/scoring_input_mapper.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';

void main() {
  group('ScoringInputMapper _minusImpact Contract Tests', () {
    test('fromTemplate mapping should preserve minusImpact for both flat and subsection criteria', () {
      // Arrange
      // Build TemplateTreeDto manually with `minusImpact`
      final template = TemplateTreeDto(
        id: 'tpl-1',
        title: 'TDD Template',
        type: 'audit',
        version: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groups: [
          // Section with a flat criterion
          GroupDto(
            id: 'sec-1',
            title: 'Section 1',
            orderIndex: 0,
            children: [
              // Subsection with a nested criterion
              GroupDto(
                id: 'sub-1',
                title: 'Subsection 1',
                orderIndex: 0,
                children: [],
                criteria: [
                  CriterionDto(
                    id: 'crit-sub',
                    label: 'Sub Criterion',
                    inputType: 'numeric',
                    pointsWeight: 10,
                    isCcp: false,
                    isRisk: false,
                    minusImpact: 6.5, // The field under test
                    orderIndex: 0,
                  ),
                ],
              ),
            ],
            criteria: [
              CriterionDto(
                id: 'crit-flat',
                label: 'Flat Criterion',
                inputType: 'numeric',
                pointsWeight: 10,
                isCcp: false,
                isRisk: false,
                minusImpact: 3.5, // The field under test
                orderIndex: 0,
              ),
            ],
          ),
        ],
      );

      final answers = <String, AuditAnswer>{};

      // Act
      final input = ScoringInputMapper.fromTemplate(template, answers);

      // Assert
      final section = input.sections.first;
      
      // Check Flat Criterion
      expect(section.criteria.length, 1);
      final flatCriterionInput = section.criteria.first;
      expect(
        flatCriterionInput.minusImpact,
        3.5,
        reason: 'Flat CriterionInput must preserve minusImpact from Template',
      );

      // Check Subsection Criterion
      expect(section.subsections.length, 1);
      final sub = section.subsections.first;
      expect(sub.criteria.length, 1);
      final subCriterionInput = sub.criteria.first;
      expect(
        subCriterionInput.minusImpact,
        6.5,
        reason: 'Subsection CriterionInput must preserve minusImpact from Template',
      );
    });
  });
}
