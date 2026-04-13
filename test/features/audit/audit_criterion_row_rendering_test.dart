import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/audit/widgets/audit_criterion_row.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/scoring_models.dart';

class MockAuditManager extends Mock implements AuditManager {}

void main() {
  late MockAuditManager mockManager;

  setUp(() {
    mockManager = MockAuditManager();
    // Default answers map mock to prevent crashes
    when(() => mockManager.answers).thenReturn({});
  });

  testWidgets('AuditCriterionRow displays +X pts in green for accumulation mode', (tester) async {
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

    // Mock answer with 4 points
    final answer = AuditAnswer(criteriaId: 'c1', numericValue: 4);
    when(() => mockManager.answers).thenReturn({'c1': answer});
    
    // RED BEHAVIOR: Current UI doesn't know about scoringMode.
    // It will render F:4 because faults = answer.numericValue.toInt() and it ignores manager.scoringMode.
    when(() => mockManager.scoringMode).thenReturn(ScoringMode.accumulation);

    // Act
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

    // Assert
    // EXPECTATION: The UI should show +4 pts because the manager is in accumulation mode.
    // This will fail currently because it renders "F:4".
    expect(find.text('+4 pts'), findsOneWidget);
    
    // Verify the color is success (green) - this is a deeper check
    final badgeText = tester.widget<Text>(find.text('+4 pts'));
    expect(badgeText.style?.color, Colors.white); // Text is white inside colored container
    

    // We expect AppTheme.success or similar. For now, checking the text exists is enough for a RED test.
  });

  testWidgets('AuditCriterionRow continues to display F:X in red for penalty mode', (tester) async {
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
          body: AuditCriterionRow(
            criterion: criterion,
            manager: mockManager,
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('F:4'), findsOneWidget);
  });

  group('Non-Scored Criteria Badges', () {
    testWidgets('displays selected option for single_choice', (tester) async {
      final criterion = CriterionDto(id: 'c1', label: 'Single', inputType: 'single_choice', isCcp: false, isRisk: false, orderIndex: 0);
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Option A');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));

      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('displays count for multi_choice', (tester) async {
      final criterion = CriterionDto(id: 'c1', label: 'Multi', inputType: 'multi_choice', isCcp: false, isRisk: false, orderIndex: 0);
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Opt1, Opt2, Opt3');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));

      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('displays truncated text for text type', (tester) async {
      final criterion = CriterionDto(id: 'c1', label: 'Text', inputType: 'text', isCcp: false, isRisk: false, orderIndex: 0);
      final answer = AuditAnswer(criteriaId: 'c1', value: 'This is a very long observation that should be truncated');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));

      expect(find.text('This is a very ...'), findsOneWidget);
    });

    testWidgets('displays PASS/FAIL for pass_fail type', (tester) async {
      final criterion = CriterionDto(id: 'c1', label: 'PF', inputType: 'pass_fail', isCcp: false, isRisk: false, orderIndex: 0);
      
      // Pass case
      when(() => mockManager.answers).thenReturn({'c1': AuditAnswer(criteriaId: 'c1', value: 'conform')});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));
      expect(find.text('PASS'), findsOneWidget);

      // Fail case
      when(() => mockManager.answers).thenReturn({'c1': AuditAnswer(criteriaId: 'c1', value: 'non_conform')});
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));
      expect(find.text('FAIL'), findsOneWidget);
    });

    testWidgets('displays selected label for scale type', (tester) async {
      final criterion = CriterionDto(id: 'c1', label: 'Scale', inputType: 'scale', isCcp: false, isRisk: false, orderIndex: 0);
      final answer = AuditAnswer(criteriaId: 'c1', value: 'Good');
      when(() => mockManager.answers).thenReturn({'c1': answer});
      when(() => mockManager.scoringMode).thenReturn(ScoringMode.penalty);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AuditCriterionRow(criterion: criterion, manager: mockManager))));

      expect(find.text('Good'), findsOneWidget);
    });
  });
}

