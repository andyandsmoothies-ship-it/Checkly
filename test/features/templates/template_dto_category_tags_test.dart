import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

void main() {
  group('Template DTO - CategoryTags parsing', () {
    test('TC-CAT-05: GroupDto parsed with categoryTags successfully', () {
      final json = {
        'id': 'group-1',
        'title': 'Front of House',
        'description': 'FOH hygiene standards',
        'weight': 1.5,
        'maxDeductionPoints': 10.0,
        'minusPerFault': 2.0,
        'orderIndex': 0,
        'metadata': '{"foo": "bar"}',
        'categoryTags': ['Food Safety', 'Cleanliness'],
        'children': [],
        'criteria': []
      };

      final group = GroupDto.fromJson(json);

      expect(group.id, 'group-1');
      expect(group.title, 'Front of House');
      expect(group.categoryTags, containsAll(['Food Safety', 'Cleanliness']));
    });

    test('TC-CAT-05: GroupDto parsed with null categoryTags gracefully', () {
      final json = {
        'id': 'group-2',
        'title': 'Back of House',
        'orderIndex': 1,
        'children': [],
        'criteria': []
      };

      final group = GroupDto.fromJson(json);

      expect(group.id, 'group-2');
      expect(group.categoryTags, isNull);
    });

    test('TC-CAT-06: CriterionDto parsed with categoryTags successfully', () {
      final json = {
        'id': 'criterion-1',
        'label': 'Temperature Log Checks',
        'description': 'Verify freezer logs',
        'inputType': 'pass_fail',
        'pointsWeight': 5.0,
        'minusImpact': 1.0,
        'maxDeductionPoints': 5.0,
        'isCcp': true,
        'isRisk': false,
        'orderIndex': 0,
        'metadata': null,
        'categoryTags': ['CCP', 'Hygiene']
      };

      final criterion = CriterionDto.fromJson(json);

      expect(criterion.id, 'criterion-1');
      expect(criterion.label, 'Temperature Log Checks');
      expect(criterion.isCcp, isTrue);
      expect(criterion.categoryTags, containsAll(['CCP', 'Hygiene']));
    });

    test('TC-CAT-06: CriterionDto parsed with null categoryTags gracefully', () {
      final json = {
        'id': 'criterion-2',
        'label': 'Clean aprons worn',
        'inputType': 'pass_fail',
        'isCcp': false,
        'isRisk': false,
        'orderIndex': 1
      };

      final criterion = CriterionDto.fromJson(json);

      expect(criterion.id, 'criterion-2');
      expect(criterion.categoryTags, isNull);
    });
  });
}
