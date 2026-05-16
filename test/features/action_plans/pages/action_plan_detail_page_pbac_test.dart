import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/_shared/constants/action_plan_actions.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/pages/action_plan_detail_page.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';

import 'package:mocktail/mocktail.dart';

class MockActionPlanManager extends Mock implements ActionPlanManager {}

class MockAuthManager extends Mock implements AuthManager {}

class MockErrorDisplayService extends Mock implements ErrorDisplayService {}

void main() {
  late MockActionPlanManager mockManager;
  late MockAuthManager mockAuth;
  late MockErrorDisplayService mockError;

  setUp(() {
    mockManager = MockActionPlanManager();
    mockAuth = MockAuthManager();
    mockError = MockErrorDisplayService();

    final di = GetIt.instance;
    di.reset();
    di.registerSingleton<ActionPlanManager>(mockManager);
    di.registerSingleton<AuthManager>(mockAuth);
    di.registerSingleton<ErrorDisplayService>(mockError);

    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockManager.isLoading).thenReturn(false);
    when(
      () => mockManager.getStaleConflict(any()),
    ).thenAnswer((_) async => null);
    when(() => mockManager.loadSinglePlan(any())).thenAnswer((_) async => true);
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: ActionPlanDetailPage(actionPlanId: 'test-id'),
    );
  }

  ActionPlanDto createPlanWithActions(String status, List<String> actions) {
    return ActionPlanDto(
      id: 'test-id',
      status: status,
      criteriaLabel: 'Label',
      groupTitle: 'Group',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      allowedActions: actions,
    );
  }

  testWidgets(
    'C4: detail page renders Submit Evidence button if allowedAction is present',
    (tester) async {
      final planNotifier = ValueNotifier([
        createPlanWithActions('open', [ActionPlanActions.submitEvidence]),
      ]);
      when(() => mockManager.actionPlans).thenReturn(planNotifier);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Submit Evidence'), findsOneWidget);
      expect(find.text('Verify & Close'), findsNothing);
    },
  );

  testWidgets(
    'C4: detail page renders Verify and Reject buttons if allowedActions are present',
    (tester) async {
      final planNotifier = ValueNotifier([
        createPlanWithActions('pending_verify', [
          ActionPlanActions.verifyClose,
          ActionPlanActions.rejectEvidence,
        ]),
      ]);
      when(() => mockManager.actionPlans).thenReturn(planNotifier);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Verify & Close'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    },
  );

  testWidgets('C4: detail page hides buttons if allowedActions are empty', (
    tester,
  ) async {
    final planNotifier = ValueNotifier([createPlanWithActions('open', [])]);
    when(() => mockManager.actionPlans).thenReturn(planNotifier);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Submit Evidence'), findsNothing);
    expect(find.text('Verify & Close'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });
}
