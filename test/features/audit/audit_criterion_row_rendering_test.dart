import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/audit/widgets/audit_criterion_row.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/scoring_mode.dart';
import 'package:checkly/features/audit/widgets/audit_status_badge.dart';

class MockAuditManager extends Mock implements AuditManager {}

void main() {
  late MockAuditManager mockManager;

  setUp(() {
    mockManager = MockAuditManager();
    // Default answers map mock to prevent crashes
    when(() => mockManager.answers).thenReturn({});
  });

  testWidgets(
    'AuditCriterionRow displays F:X in red for numeric input in accumulation mode',
    (tester) async {
      // Arrange
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Test Criterion',
        inputType: 'numeric',
        pointsWeight: 10,
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );

      final answer = AuditAnswer(criteriaId: 'c1', numericValue: 4);
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.accumulation);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      // Assert
      // CORRECT EXPECTATION: numeric inputs ALWAYS represent defect counts, never earned points.
      // The ScoringEngine treats numeric as binary fault — so the UI must always show F:X in red.
      expect(find.text('F:4'), findsOneWidget);
      expect(find.text('+4 pts'), findsNothing);
    },
  );

  testWidgets(
    'AuditCriterionRow continues to display F:X in red for penalty mode',
    (tester) async {
      // Arrange
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Test Criterion',
        inputType: 'numeric',
        pointsWeight: 10,
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );

      final answer = AuditAnswer(criteriaId: 'c1', numericValue: 4);
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      // Assert
      expect(find.text('F:4'), findsOneWidget);
    },
  );

  group('Non-Scored Criteria Badges', () {
    testWidgets('displays selected option for single_choice without badge', (
      tester,
    ) async {
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Single',
        inputType: 'single_choice',
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Option A');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      // New constraint: Should NOT be in a badge
      expect(
        find.ancestor(
          of: find.text('Option A'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsNothing,
      );
    });

    testWidgets('displays count for multi_choice INSIDE badge', (tester) async {
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Multi',
        inputType: 'multi_choice',
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Opt1, Opt2, Opt3');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      expect(find.text('3 selected'), findsOneWidget);
      // multi_choice remains as a badge
      expect(
        find.ancestor(
          of: find.text('3 selected'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'displays full text for text type without badge and without truncation',
      (tester) async {
        final criterion = CriterionDto(
          id: 'c1',
          label: 'Text',
          inputType: 'text',
          isCcp: false,
          isRisk: false,
          orderIndex: 0,
        );
        final answer = AuditAnswer(
          criteriaId: 'c1',
          value:
              'This is a long observation that should not be truncated anymore',
        );
        when(() => mockManager.answers).thenReturn({'c1': answer});
        when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AuditCriterionRow(
                criterion: criterion,
                manager: mockManager,
              ),
            ),
          ),
        );

        // Should find full text
        expect(
          find.text(
            'This is a long observation that should not be truncated anymore',
          ),
          findsOneWidget,
        );
        // New constraint: Should NOT be in a badge
        expect(
          find.ancestor(
            of: find.textContaining('This is a long'),
            matching: find.byType(AuditStatusBadge),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('displays PASS/FAIL for pass_fail type INSIDE badge', (
      tester,
    ) async {
      final criterion = CriterionDto(
        id: 'c1',
        label: 'PF',
        inputType: 'pass_fail',
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );

      // Pass case
      when(
        () => mockManager.answers,
      ).thenReturn({'c1': AuditAnswer(criteriaId: 'c1', value: 'conform')});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );
      expect(find.text('PASS'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('PASS'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsOneWidget,
      );

      // Fail case
      when(
        () => mockManager.answers,
      ).thenReturn({'c1': AuditAnswer(criteriaId: 'c1', value: 'non_conform')});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );
      expect(find.text('FAIL'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('FAIL'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays selected label for scale type without badge', (
      tester,
    ) async {
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Scale',
        inputType: 'scale',
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Excellent');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      expect(find.text('Excellent'), findsOneWidget);
      // Scale label moves out of badge
      expect(
        find.ancestor(
          of: find.text('Excellent'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsNothing,
      );
    });

    testWidgets('displays scale label AND points badge in accumulation mode', (
      tester,
    ) async {
      final criterion = CriterionDto(
        id: 'c1',
        label: 'Scale',
        inputType: 'scale',
        isCcp: false,
        isRisk: false,
        orderIndex: 0,
      );
      final answer = AuditAnswer(
        criteriaId: 'c1',
        value: 'Good',
        numericValue: 3,
      );
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.accumulation);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditCriterionRow(criterion: criterion, manager: mockManager),
          ),
        ),
      );

      // Label (no badge)
      expect(find.text('Good'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Good'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsNothing,
      );

      // Points (badge)
      expect(find.text('+3 pts'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('+3 pts'),
          matching: find.byType(AuditStatusBadge),
        ),
        findsOneWidget,
      );
    });
  });
}
