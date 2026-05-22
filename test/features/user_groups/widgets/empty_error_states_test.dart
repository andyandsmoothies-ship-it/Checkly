import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/user_groups/widgets/empty_state.dart';
import 'package:checkly/features/user_groups/widgets/error_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('Renders all text elements and invokes callback on tap', (
      tester,
    ) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onCreate: () {
                called = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.group_work_outlined), findsOneWidget);
      expect(find.text('No user groups yet'), findsOneWidget);
      expect(
        find.text(
          'User groups let you organize team members for assignment and reporting.',
        ),
        findsOneWidget,
      );

      final buttonFinder = find.widgetWithText(
        FilledButton,
        'Create First Group',
      );
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(called, isTrue);
    });
  });

  group('ErrorState Widget Tests', () {
    testWidgets('Renders message and invokes callback on tap', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              message: 'Custom error message',
              onRetry: () {
                called = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Custom error message'), findsOneWidget);

      final buttonFinder = find.widgetWithText(OutlinedButton, 'Retry');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
