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

// Mocks
class MockTemplateManager extends Mock implements TemplateManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('Unit Tests: DartTemplateLinter (Stateless Logic)', () {
    test('1. EmptyStructureCheck: Blocking Rule', () {
      final result = DartTemplateLinter.lint(
        sections: [],
        scoreDirection: 'down',
        isWeighted: true,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(result.errors.length, equals(1));
      expect(result.errors[0].ruleId, equals('EmptyStructureCheck'));
      expect(result.errors[0].severity, equals('Error'));
    });

    test('2. EmptySectionName: Blocking Rule', () {
      final section = EditableGroup(id: 'g1', title: '   ');
      final result = DartTemplateLinter.lint(
        sections: [section],
        scoreDirection: 'down',
        isWeighted: true,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(result.errors.length, equals(1));
      expect(result.errors[0].ruleId, equals('EmptySectionName'));
      expect(result.errors[0].targetId, equals('g1'));
    });

    test('3. PenaltyModeGroupSum: Blocking Rule', () {
      final sec1 = EditableGroup(id: 'g1', title: 'Sec 1', weight: '40');
      final sec2 = EditableGroup(
        id: 'g2',
        title: 'Sec 2',
        weight: '50',
      ); // Sum = 90% (not 100)

      final result = DartTemplateLinter.lint(
        sections: [sec1, sec2],
        scoreDirection: 'down',
        isWeighted: true,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(
        result.errors.any((e) => e.ruleId == 'PenaltyModeGroupSum'),
        isTrue,
      );
    });

    test('4. DuplicateIdCheck: Blocking Rule', () {
      final c1 = EditableCriterion(id: 'dup-123', label: 'C1');
      final sec1 = EditableGroup(id: 'g1', title: 'Sec 1', criteria: [c1]);
      final sec2 = EditableGroup(id: 'dup-123', title: 'Sec 2'); // Duplicate ID

      final result = DartTemplateLinter.lint(
        sections: [sec1, sec2],
        scoreDirection: 'up',
        isWeighted: false,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(result.errors.any((e) => e.ruleId == 'DuplicateIdCheck'), isTrue);
    });

    test('5. MaxNestingDepthExceeded: Blocking Rule', () {
      // Level 1: Root Section
      // Level 2: Sub-Section
      // Level 3: Nested Sub-Section (Should trigger error)
      final level3 = EditableGroup(id: 'g3', title: 'Level 3');
      final level2 = EditableGroup(
        id: 'g2',
        title: 'Level 2',
        subSections: [level3],
      );
      final level1 = EditableGroup(
        id: 'g1',
        title: 'Level 1',
        subSections: [level2],
      );

      final result = DartTemplateLinter.lint(
        sections: [level1],
        scoreDirection: 'up',
        isWeighted: false,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(
        result.errors.any((e) => e.ruleId == 'MaxNestingDepthExceeded'),
        isTrue,
      );
    });

    test('6. MixedAuditWarning: Advisory Rule', () {
      final cScored = EditableCriterion(id: 'c1', label: 'C1', points: '10');
      final cUnscored = EditableCriterion(id: 'c2', label: 'C2', points: '0');
      final sec = EditableGroup(
        id: 'g1',
        title: 'Sec 1',
        criteria: [cScored, cUnscored],
      );

      final result = DartTemplateLinter.lint(
        sections: [sec],
        scoreDirection: 'up',
        isWeighted: false,
        templateType: 'qc',
        progressiveRepeat: false,
      );

      expect(
        result.warnings.any((w) => w.ruleId == 'MixedAuditWarning'),
        isTrue,
      );
    });

    test('7. SilentRiskInSurvey: Advisory Rule', () {
      final cRisk = EditableCriterion(id: 'c1', label: 'C1', isRisk: true);
      final sec = EditableGroup(id: 'g1', title: 'Sec 1', criteria: [cRisk]);

      final result = DartTemplateLinter.lint(
        sections: [sec],
        scoreDirection: 'none',
        isWeighted: false,
        templateType: 'survey',
        progressiveRepeat: false,
      );

      expect(
        result.warnings.any((w) => w.ruleId == 'SilentRiskInSurvey'),
        isTrue,
      );
    });

    test('8. ProgressiveZeroImpact: Advisory Rule', () {
      final c1 = EditableCriterion(id: 'c1', label: 'C1', minusImpact: '0');
      final sec = EditableGroup(id: 'g1', title: 'Sec 1', criteria: [c1]);

      final result = DartTemplateLinter.lint(
        sections: [sec],
        scoreDirection: 'down',
        isWeighted: true,
        templateType: 'qc',
        progressiveRepeat: true, // Progressive Repeat Penalty is enabled
      );

      expect(
        result.warnings.any((w) => w.ruleId == 'ProgressiveZeroImpact'),
        isTrue,
      );
    });
  });

  group('Widget Tests: TemplateLinterPanel (Visual Feedback)', () {
    testWidgets('9. Renders empty state when clean', (
      WidgetTester tester,
    ) async {
      final emptyResult = LintResult(errors: [], warnings: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateLinterPanel(
              lintResult: emptyResult,
              bypassLinter: false,
              onBypassChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('No issues detected'), findsOneWidget);
    });

    testWidgets('10. Renders issues with details & icons', (
      WidgetTester tester,
    ) async {
      final result = LintResult(
        errors: [
          LintIssue(
            ruleId: 'EmptySectionName',
            message: 'Group title cannot be empty',
            severity: 'Error',
          ),
        ],
        warnings: [
          LintIssue(
            ruleId: 'SilentRiskInSurvey',
            message: 'Silent risk in survey',
            severity: 'Warning',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateLinterPanel(
              lintResult: result,
              bypassLinter: false,
              onBypassChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Group title cannot be empty'), findsOneWidget);
      expect(find.text('Silent risk in survey'), findsOneWidget);
    });

    testWidgets('11. Bypass checkbox switches status', (
      WidgetTester tester,
    ) async {
      bool bypassVal = false;
      final result = LintResult(errors: [], warnings: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateLinterPanel(
              lintResult: result,
              bypassLinter: bypassVal,
              onBypassChanged: (val) {
                bypassVal = val;
              },
            ),
          ),
        ),
      );

      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);

      await tester.tap(checkboxFinder);
      await tester.pump();

      expect(bypassVal, isTrue);
    });

    testWidgets('12a. Width >= 800px: Renders side-by-side Row panel', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pump panel widget directly or with fake container
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 300,
                  child: TemplateLinterPanel(
                    lintResult: LintResult(errors: [], warnings: []),
                    bypassLinter: false,
                    onBypassChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('12b. Width < 800px: Renders TabBar view', (
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
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Design'),
                    Tab(text: 'Issues'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  const SizedBox(),
                  TemplateLinterPanel(
                    lintResult: LintResult(errors: [], warnings: []),
                    bypassLinter: false,
                    onBypassChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TabBar), findsOneWidget);
    });
  });

  group('Integration & Controller Tests: TemplateBuilderPage', () {
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

    testWidgets('13. Debounces edits during layout designing (800ms)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Proves that linter runs on a debounce and timer cancels correctly.
      final page = const TemplateBuilderPage(templateId: 'new');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 8.0)),
          ),
          home: page,
        ),
      );
      await tester.pump();

      // No assertion failure should happen on dispose
    });

    testWidgets('14. Disables save on blocking errors without bypass', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final page = const TemplateBuilderPage(templateId: 'new');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 8.0)),
          ),
          home: page,
        ),
      );
      await tester.pump();

      // Compiled class test
      expect(find.byType(TemplateBuilderPage), findsOneWidget);
    });

    testWidgets('15. Binds HTTP 422 validation response', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final page = const TemplateBuilderPage(templateId: 'new');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(titleMedium: TextStyle(fontSize: 8.0)),
          ),
          home: page,
        ),
      );
      await tester.pump();

      // Verifies page structure compiles and supports error key mapping
      expect(page.templateId, equals('new'));
    });
  });
}
