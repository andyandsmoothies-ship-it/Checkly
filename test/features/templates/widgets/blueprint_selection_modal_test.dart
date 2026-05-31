import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/widgets/blueprint_selection_modal.dart';

void main() {
  group('BlueprintSelectionModal - UI and Copywriting Tests', () {
    testWidgets('Renders all five blueprints with correct enriched descriptions', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlueprintSelectionModal(),
          ),
        ),
      );

      // 1. Verify modal title
      expect(find.text('What are you building?'), findsOneWidget);

      // 2. Verify titles of the blueprints
      expect(find.text('Audit & Inspection'), findsOneWidget);
      expect(find.text('Scored Assessment'), findsOneWidget);
      expect(find.text('Simple Scored Assessment'), findsOneWidget);
      expect(find.text('Form & Survey'), findsOneWidget);
      expect(find.text('Basic Checklist'), findsOneWidget);

      // 3. Verify enriched descriptions are present
      expect(
        find.textContaining('Deduct Points (Weighted): Start with a perfect 100% score.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Earn Points (Weighted): Start at 0% score.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Earn Points (Simple): Start at 0% score.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No Scoring (Survey): Gather answers without calculating any score.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Deduct Points (Simple): Start with a perfect 100% score.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping a blueprint card pops modal with correct mode', (tester) async {
      String? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedMode = await showDialog<String>(
                      context: context,
                      builder: (context) => const BlueprintSelectionModal(),
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap on "Basic Checklist"
      await tester.tap(find.text('Basic Checklist'));
      await tester.pumpAndSettle();

      // Verify that basic checklist mode was returned
      expect(selectedMode, equals('checklist'));
    });
  });
}
