import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/models/editable_group.dart';
import 'package:checkly/features/templates/widgets/wizard_step_sections.dart';

void main() {
  group('WizardStepSections - Section Weighting Input Gap Tests', () {
    late List<EditableGroup> sections;

    setUp(() {
      sections = [
        EditableGroup()..titleCtrl.text = 'Safety Section',
      ];
    });

    testWidgets('Renders weight text field and % when weightedDensity is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WizardStepSections(
              sections: sections,
              scoringMode: 'accumulation',
              currentSectionIndex: 0,
              weightedDensity: true,
              onChanged: () {},
              onSectionChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify that the weight field input and % suffix are visible.
      expect(find.text('%'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Weight field
    });

    testWidgets('Does not render weight field or % when weightedDensity is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WizardStepSections(
              sections: sections,
              scoringMode: 'accumulation',
              currentSectionIndex: 0,
              weightedDensity: false,
              onChanged: () {},
              onSectionChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify that the weight % suffix is not visible, and no TextField is visible.
      expect(find.text('%'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
