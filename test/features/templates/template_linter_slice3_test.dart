import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/templates/models/editable_criterion.dart';
import 'package:checkly/features/templates/models/editable_group.dart';
import 'package:checkly/features/templates/models/lint_result.dart';
import 'package:checkly/features/templates/utils/dart_template_linter.dart';
import 'package:checkly/features/templates/widgets/template_linter_panel.dart';
import 'package:checkly/features/templates/pages/template_builder_page.dart';
import 'package:checkly/features/templates/manager/template_manager.dart';
import 'package:checkly/features/templates/pages/widgets/live_score_simulator.dart';

// Mocks
class MockTemplateManager extends Mock implements TemplateManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('Widget Tests: LiveScoreSimulator', () {
    testWidgets('1. All criteria passing -> simulator shows 100%', (
      WidgetTester tester,
    ) async {
      final section = EditableGroup(
        id: 'g1',
        title: 'Section 1',
        weight: '100',
        criteria: [
          EditableCriterion(
            id: 'c1',
            label: 'Question 1',
            points: '10',
            inputType: 'pass_fail',
          ),
          EditableCriterion(
            id: 'c2',
            label: 'Question 2',
            points: '10',
            inputType: 'pass_fail',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveScoreSimulator(
              sections: [section],
              scoringMode: 'penalty',
              progressiveRepeat: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show 100% score initially
      expect(find.textContaining('100.00%'), findsOneWidget);
      expect(find.textContaining('RISK'), findsNothing);
    });

    testWidgets('2. One pass_fail failed -> simulator shows decreased score', (
      WidgetTester tester,
    ) async {
      final section = EditableGroup(
        id: 'g1',
        title: 'Section 1',
        weight: '100',
        criteria: [
          EditableCriterion(
            id: 'c1',
            label: 'Question 1',
            points: '10',
            inputType: 'pass_fail',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveScoreSimulator(
              sections: [section],
              scoringMode: 'penalty',
              progressiveRepeat: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the toggle/switch for c1 and toggle it (simulates failure)
      final toggleFinder = find.byType(Switch).first;
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Score should drop to 90% (since weight is 100 and pointsWeight is 10, total points = 10, deduction = 1.0 out of 10.0)
      expect(find.textContaining('90.00%'), findsOneWidget);
    });

    testWidgets(
      '3. Any isRisk=true criterion failed -> RISK alert and score 0%',
      (WidgetTester tester) async {
        final section = EditableGroup(
          id: 'g1',
          title: 'Section 1',
          weight: '100',
          criteria: [
            EditableCriterion(
              id: 'c1',
              label: 'Question 1',
              points: '10',
              inputType: 'pass_fail',
              isRisk: true,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiveScoreSimulator(
                sections: [section],
                scoringMode: 'penalty',
                progressiveRepeat: false,
              ),
            ),
          ),
        );

        await tester.pump();

        // Fail the risk criterion
        final toggleFinder = find.byType(Switch).first;
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();

        // Should show forced 0.00% score and a RISK alert badge
        expect(find.textContaining('0.00%'), findsOneWidget);
        expect(find.textContaining('RISK FAILURE'), findsOneWidget);
      },
    );

    testWidgets('4. Survey mode -> simulator shows no score message', (
      WidgetTester tester,
    ) async {
      final section = EditableGroup(
        id: 'g1',
        title: 'Section 1',
        weight: '100',
        criteria: [
          EditableCriterion(
            id: 'c1',
            label: 'Question 1',
            points: '10',
            inputType: 'text',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveScoreSimulator(
              sections: [section],
              scoringMode: 'survey',
              progressiveRepeat: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render survey bypass explanation instead of percentage
      expect(find.textContaining('Survey — no score'), findsOneWidget);
    });

    testWidgets('5. Mixed audit -> simulator shows null score message', (
      WidgetTester tester,
    ) async {
      final section = EditableGroup(
        id: 'g1',
        title: 'Section 1',
        weight: '100',
        criteria: [
          EditableCriterion(
            id: 'c1',
            label: 'Question 1',
            points: '10',
            inputType: 'pass_fail',
          ),
          EditableCriterion(
            id: 'c2',
            label: 'Question 2',
            points: '0',
            inputType: 'pass_fail',
          ), // Pointless scored item
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveScoreSimulator(
              sections: [section],
              scoringMode: 'penalty',
              progressiveRepeat: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should trigger purity check and suppress score
      expect(find.textContaining('Mixed — score will be NULL'), findsOneWidget);
    });

    testWidgets('6. Simulating global risk -> score forced to 0% immediately', (
      WidgetTester tester,
    ) async {
      final section = EditableGroup(
        id: 'g1',
        title: 'Section 1',
        weight: '100',
        criteria: [
          EditableCriterion(
            id: 'c1',
            label: 'Question 1',
            points: '10',
            inputType: 'pass_fail',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveScoreSimulator(
              sections: [section],
              scoringMode: 'penalty',
              progressiveRepeat: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Find the Global Risk checkbox/switch at the top and check it
      final globalRiskFinder = find.byKey(
        const ValueKey('simulate_global_risk'),
      );
      expect(globalRiskFinder, findsOneWidget);
      await tester.tap(globalRiskFinder);
      await tester.pumpAndSettle();

      // Score must drop to 0% and show forced risk badge
      expect(find.textContaining('0.00%'), findsOneWidget);
      expect(find.textContaining('GLOBAL RISK ACTIVE'), findsOneWidget);
    });
  });

  group('Widget Tests: Responsive Layout & Tabs', () {
    late MockTemplateManager mockManager;

    setUp(() {
      GetIt.I.allowReassignment = true;
      mockManager = MockTemplateManager();
      when(() => mockManager.isLoading).thenReturn(ValueNotifier(false));
      when(() => mockManager.error).thenReturn(null);
      GetIt.I.registerSingleton<TemplateManager>(mockManager);
    });

    tearDown(() {
      GetIt.I.reset();
    });

    testWidgets(
      '7. Desktop (width >= 800px) -> renders Row with 3-column layout',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 8.0)),
            ),
            home: const TemplateBuilderPage(templateId: 'new'),
          ),
        );

        await tester.pump();

        // Desktop layout expects the parent Row
        expect(find.byType(Row), findsAtLeastNWidgets(1));
        // Should find TemplateLinterPanel AND LiveScoreSimulator simultaneously
        expect(find.byType(TemplateLinterPanel), findsOneWidget);
        expect(find.byType(LiveScoreSimulator), findsOneWidget);
        // No TabBar should render on desktop layout
        expect(find.byType(TabBar), findsNothing);
      },
    );

    testWidgets('8. Mobile (width < 800px) -> renders TabBarView with 3 tabs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 8.0)),
          ),
          home: const TemplateBuilderPage(templateId: 'new'),
        ),
      );

      await tester.pump();

      // TabBar controller and view must exist
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);

      // Verify that there are 3 tabs: Design, Issues, and Simulator
      final tabFinder = find.byType(Tab);
      expect(tabFinder, findsNWidgets(3));
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Simulator'), findsOneWidget);
    });
  });
}
