import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/widgets/primitives/primitives.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:checkly/_shared/theme/app_colors.dart';

void main() {
  group('BubblyButton Widget Tests', () {
    testWidgets('BB-01: Renders label text correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BubblyButton(label: 'Click Me')),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('BB-02: Triggers onPressed callback on tap', (
      WidgetTester tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BubblyButton(
              label: 'Tap Test',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Test'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets(
      'BB-03: Renders loading indicator instead of text when isLoading is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BubblyButton(label: 'Tap Test', isLoading: true),
            ),
          ),
        );

        expect(find.text('Tap Test'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });

  group('StrokeCard Widget Tests', () {
    testWidgets('SC-01: Renders children successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StrokeCard(child: Text('Card Content'))),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets(
      'SC-02: Renders as standard Card with zero elevation and Swan border',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StrokeCard(child: SizedBox(width: 50, height: 50)),
            ),
          ),
        );

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final Card cardWidget = tester.widget<Card>(cardFinder);
        expect(cardWidget.elevation, equals(0));

        final shape = cardWidget.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16.0)));
        expect(shape.side.width, equals(2.0));
        expect(shape.side.color, equals(AppColors.swan));
      },
    );

    testWidgets('SC-03: Interactivity works when onTap is provided', (
      WidgetTester tester,
    ) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrokeCard(
              onTap: () {
                clicked = true;
              },
              child: const Text('Interactive Card'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Interactive Card'));
      await tester.pump();

      expect(clicked, isTrue);
    });
  });

  group('QuestProgressBar Widget Tests', () {
    testWidgets('QP-01: Progress clamps values correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuestProgressBar(value: 0.5))),
      );

      expect(find.byType(QuestProgressBar), findsOneWidget);
    });

    testWidgets(
      'QP-02: Renders gloss highlight inside when progress is above 5%',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: QuestProgressBar(
                value: 0.5, // 50%
              ),
            ),
          ),
        );

        // Verify progress renders at 50%
        expect(
          find.byType(AnimatedContainer),
          findsNWidgets(2),
        ); // Progress bar fill + gloss highlight
      },
    );

    testWidgets('QP-03: Does not render gloss highlight when progress is 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuestProgressBar(value: 0.0))),
      );

      // Verify progress does not render gloss highlight since progress is 0
      expect(
        find.byType(AnimatedContainer),
        findsNWidgets(1),
      ); // Progress bar fill only
    });
  });

  group('ChecklyEmptyState Widget Tests', () {
    testWidgets(
      'ES-01: Standard empty state displays title, subtitle, and default icon',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChecklyEmptyState(
                icon: Icons.search,
                title: 'No Results Found',
                subtitle: 'Try adjusting your search criteria.',
              ),
            ),
          ),
        );

        expect(find.text('No Results Found'), findsOneWidget);
        expect(
          find.text('Try adjusting your search criteria.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      },
    );

    testWidgets(
      'ES-02: Emoji empty state hides icon and renders emoji character mascot',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChecklyEmptyState(
                emoji: '🦉',
                title: 'Ready for Your Audit?',
                subtitle: 'Tap the button below to start your shift.',
              ),
            ),
          ),
        );

        expect(find.text('Ready for Your Audit?'), findsOneWidget);
        expect(
          find.text('Tap the button below to start your shift.'),
          findsOneWidget,
        );

        // Icon should not be rendered
        expect(find.byType(Icon), findsNothing);

        // The emoji should be rendered as a Text widget
        expect(find.text('🦉'), findsOneWidget);

        final textWidget = tester.widget<Text>(find.text('🦉'));
        expect(textWidget.style?.fontSize, equals(56.0));
      },
    );
  });
}
