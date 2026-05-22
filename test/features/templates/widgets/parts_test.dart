import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/models/editable_group.dart';
import 'package:checkly/features/templates/widgets/section_editor.dart';
import 'package:checkly/features/templates/widgets/wizard_step_sections.dart';

void main() {
  group('Template Widget Parts - Public Isolation Tests', () {
    testWidgets('SectionErrorMessages - Renders errors when provided', (
      tester,
    ) async {
      const errors = ['Title is required', 'Criteria cannot be empty'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SectionErrorMessages(errors: errors)),
        ),
      );

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Criteria cannot be empty'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    });

    testWidgets('SectionErrorMessages - Renders empty when errors are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SectionErrorMessages(errors: [])),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('WizardModeBanner - Renders correctly in Survey Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WizardModeBanner(scoringMode: 'survey')),
        ),
      );

      expect(
        find.textContaining(
          'Survey Mode — Sub-sections and scoring logic are disabled.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    testWidgets('WizardModeBanner - Renders correctly in Checklist Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WizardModeBanner(scoringMode: 'checklist')),
        ),
      );

      expect(
        find.textContaining('Checklist Mode — Keep it flat with Pass / Fail'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    });

    testWidgets('WizardModeBanner - Renders empty for other modes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WizardModeBanner(scoringMode: 'penalty')),
        ),
      );

      expect(find.byType(Container), findsNothing);
    });

    testWidgets('SectionEditorHeader - Renders correct counts and title', (
      tester,
    ) async {
      final section = EditableGroup();
      section.titleCtrl.text = 'Safety Checks';
      bool changed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionEditorHeader(
              section: section,
              index: 0,
              isRoot: true,
              densityEnabled: false,
              subCount: 3,
              critCount: 12,
              onChanged: () {
                changed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('3S \u2022 12C'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Cleanliness');
      expect(changed, isTrue);
    });

    testWidgets(
      'WizardSectionProgressHeader - Renders correct index and sub-text',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WizardSectionProgressHeader(
                sectionTitle: 'Production Area',
                currentIdx: 1,
                sectionCount: 4,
                countLabel: '12 criteria \u2022 2 sub-sections',
              ),
            ),
          ),
        );

        expect(find.text('Section 2 of 4'), findsOneWidget);
        expect(find.text('Production Area'), findsOneWidget);
        expect(find.text('12 criteria \u2022 2 sub-sections'), findsOneWidget);
      },
    );
  });
}
