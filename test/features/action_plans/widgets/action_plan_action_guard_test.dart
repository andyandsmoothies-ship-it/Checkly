import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/constants/action_plan_actions.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/widgets/action_plan_action_guard.dart';

void main() {
  // Test Plan:
  // 1. Render child when the action is in allowedActions.
  // 2. Hide child (render fallback) when the action is missing.
  // 3. Hide child (render fallback) when allowedActions is null.
  // 4. Render fallback explicitly if provided.

  Widget buildTestWidget({
    required ActionPlanDto plan,
    required String requiredAction,
    Widget? fallback,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: fallback == null
            ? ActionPlanActionGuard(
                plan: plan,
                requiredAction: requiredAction,
                child: const Text('Visible Child'),
              )
            : ActionPlanActionGuard(
                plan: plan,
                requiredAction: requiredAction,
                fallback: fallback,
                child: const Text('Visible Child'),
              ),
      ),
    );
  }

  ActionPlanDto createPlanWithActions(List<String>? actions) {
    return ActionPlanDto(
      id: 'test-id',
      status: 'open',
      criteriaLabel: 'Label',
      groupTitle: 'Group',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      allowedActions: actions,
    );
  }

  testWidgets(
    'C1: ActionPlanActionGuard renders child when action is allowed',
    (tester) async {
      final plan = createPlanWithActions([
        ActionPlanActions.submitEvidence,
        ActionPlanActions.view,
      ]);

      await tester.pumpWidget(
        buildTestWidget(
          plan: plan,
          requiredAction: ActionPlanActions.submitEvidence,
        ),
      );

      expect(find.text('Visible Child'), findsOneWidget);
    },
  );

  testWidgets('C1: ActionPlanActionGuard hides child when action is missing', (
    tester,
  ) async {
    final plan = createPlanWithActions([ActionPlanActions.view]);

    await tester.pumpWidget(
      buildTestWidget(
        plan: plan,
        requiredAction: ActionPlanActions.submitEvidence,
      ),
    );

    expect(find.text('Visible Child'), findsNothing);
  });

  testWidgets(
    'C1: ActionPlanActionGuard hides child when allowedActions is null',
    (tester) async {
      final plan = createPlanWithActions(null);

      await tester.pumpWidget(
        buildTestWidget(
          plan: plan,
          requiredAction: ActionPlanActions.submitEvidence,
        ),
      );

      expect(find.text('Visible Child'), findsNothing);
    },
  );

  testWidgets(
    'C1: ActionPlanActionGuard renders custom fallback when action is missing',
    (tester) async {
      final plan = createPlanWithActions([ActionPlanActions.view]);

      await tester.pumpWidget(
        buildTestWidget(
          plan: plan,
          requiredAction: ActionPlanActions.submitEvidence,
          fallback: const Text('Hidden Child'),
        ),
      );

      expect(find.text('Visible Child'), findsNothing);
      expect(find.text('Hidden Child'), findsOneWidget);
    },
  );
}
