// Test Plan:
// Covers TC-PBAC-01 from the PBAC Phase A implementation plan.
// Spec: PermissionGuard must support a `showAsDisabled` parameter.
// When the user lacks the required capability AND showAsDisabled=true,
// the child widget should be rendered but visually disabled (IgnorePointer)
// and optionally wrapped with a Tooltip explaining the denial.
//
// Input Lineage:
// C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md
//
// Why these tests will fail (RED phase):
// PermissionGuard at lib/_shared/widgets/permission_guard.dart has no `showAsDisabled`
// parameter. The constructor only accepts `capability`, `child`, and `fallback`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/_shared/widgets/permission_guard.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';

class MockAuthManager extends Mock implements AuthManager {}

class MockPolicyManager extends Mock implements PolicyManager {}

void main() {
  setUp(() {
    GetIt.I.allowReassignment = true;
  });

  tearDown(() {
    GetIt.I.reset();
  });

  /// Helper: registers GetIt stubs and pumps a test widget with PermissionGuard.
  ///
  /// [hasCapability]    — whether the mock returns true for can('submissions:create').
  /// [showAsDisabled]   — passed to the PermissionGuard under test.
  /// [disabledTooltip]  — optional tooltip text to show when disabled.
  Future<void> pumpGuard(
    WidgetTester tester, {
    required bool hasCapability,
    required bool showAsDisabled,
    String? disabledTooltip,
  }) async {
    final mockAuth = MockAuthManager();
    final mockPolicy = MockPolicyManager();

    final notifier = ValueNotifier<Set<String>>(
      hasCapability ? {'submissions:create'} : <String>{},
    );
    when(() => mockAuth.capabilities).thenReturn(notifier);
    when(() => mockPolicy.can('submissions:create')).thenReturn(hasCapability);

    GetIt.I.registerSingleton<AuthManager>(mockAuth);
    GetIt.I.registerSingleton<PolicyManager>(mockPolicy);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PermissionGuard(
            capability: 'submissions:create',
            showAsDisabled: showAsDisabled,
            disabledTooltip: disabledTooltip,
            child: ElevatedButton(
              key: const Key('guarded_button'),
              onPressed: () {},
              child: const Text('Start Audit'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // ── TC-PBAC-01: Happy Path ─────────────────────────────────────────────────

  testWidgets(
    'TC-PBAC-01a: PermissionGuard_showAsDisabled_true_WithCapability_RendersInteractiveChild',
    (WidgetTester tester) async {
      // Arrange + Act
      await pumpGuard(tester, hasCapability: true, showAsDisabled: false);

      // Assert: child must be fully interactive (no IgnorePointer wrapping it)
      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.descendant(
          of: find.byKey(const Key('guarded_button')),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(find.text('Start Audit'), findsOneWidget);
      expect(ignorePointers, isEmpty);
    },
  );

  // ── TC-PBAC-01: Core Contract — disabled state ─────────────────────────────

  testWidgets(
    'TC-PBAC-01b: PermissionGuard_showAsDisabled_true_WithoutCapability_RendersDisabledChild',
    (WidgetTester tester) async {
      // Arrange + Act
      await pumpGuard(tester, hasCapability: false, showAsDisabled: true);

      // Assert: child MUST still exist in the tree (not hidden)
      expect(
        find.text('Start Audit'),
        findsOneWidget,
        reason: 'showAsDisabled=true must render the child, not hide it',
      );

      // Assert: child MUST be wrapped by IgnorePointer to block taps
      expect(
        find.byType(IgnorePointer),
        findsWidgets,
        reason:
            'Disabled child must be wrapped with IgnorePointer to block interaction',
      );
    },
  );

  testWidgets(
    'TC-PBAC-01c: PermissionGuard_showAsDisabled_false_WithoutCapability_HidesChild',
    (WidgetTester tester) async {
      // Arrange + Act: showAsDisabled=false is the default hide behavior
      await pumpGuard(tester, hasCapability: false, showAsDisabled: false);

      // Assert: child must be hidden (existing behavior must be preserved)
      expect(
        find.text('Start Audit'),
        findsNothing,
        reason: 'Default behavior (showAsDisabled=false) must hide the child',
      );
    },
  );

  // ── TC-PBAC-01: Tooltip ───────────────────────────────────────────────────

  testWidgets(
    'TC-PBAC-01d: PermissionGuard_showAsDisabled_WithTooltip_ShowsTooltipText',
    (WidgetTester tester) async {
      // Arrange + Act
      await pumpGuard(
        tester,
        hasCapability: false,
        showAsDisabled: true,
        disabledTooltip: 'You need the Auditor role to start an audit.',
      );

      // Assert: a Tooltip widget must exist in the tree
      expect(
        find.byType(Tooltip),
        findsWidgets,
        reason: 'A Tooltip must wrap the disabled widget to explain the denial',
      );

      // Assert: the tooltip message must match the provided text
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final messages = tooltips.map((t) => t.message).toList();
      expect(
        messages,
        contains('You need the Auditor role to start an audit.'),
        reason: 'Tooltip message must match the disabledTooltip parameter',
      );
    },
  );

  // ── TC-PBAC-01: Edge Case — tooltip null when showAsDisabled=true ──────────

  testWidgets(
    'TC-PBAC-01e: PermissionGuard_showAsDisabled_NoTooltip_DisabledWithNoTooltipWidget',
    (WidgetTester tester) async {
      // Arrange + Act
      await pumpGuard(
        tester,
        hasCapability: false,
        showAsDisabled: true,
        disabledTooltip: null, // no tooltip provided
      );

      // Assert: child is still rendered as disabled
      expect(find.text('Start Audit'), findsOneWidget);
      expect(find.byType(IgnorePointer), findsWidgets);

      // Assert: no Tooltip widget since disabledTooltip was null
      final guardedTooltips = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .where((t) => t.message?.isNotEmpty == true)
          .toList();
      expect(
        guardedTooltips,
        isEmpty,
        reason: 'No tooltip should appear if disabledTooltip is null',
      );
    },
  );
}
