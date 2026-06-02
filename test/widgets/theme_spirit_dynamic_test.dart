import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/_shared/theme/app_theme_notifier.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import 'package:checkly/_shared/widgets/primitives/bubbly_button.dart';

void main() {
  group('Dynamic Theme Spirit Swapping Widget Tests', () {
    testWidgets(
      'Should dynamically swap aesthetics between Duolingo (tactile) and Minimalist (flat) modes',
      (WidgetTester tester) async {
        final spiritNotifier = ThemeSpiritNotifier();

        // 1. Pump the widget tree wrapped in ValueListenableBuilder
        await tester.pumpWidget(
          ValueListenableBuilder<ThemeSpirit>(
            valueListenable: spiritNotifier,
            builder: (context, spirit, _) {
              return MaterialApp(
                theme: AppTheme.light,
                home: const Scaffold(
                  body: Column(
                    children: [
                      StrokeCard(
                        child: Text('Dynamic Card'),
                      ),
                      SizedBox(height: 20),
                      BubblyButton(
                        label: 'Dynamic Button',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        // --- VERIFY DUOLINGO SPIRIT (Default) ---
        // StrokeCard assertions
        final cardFinder = find.descendant(
          of: find.byType(StrokeCard),
          matching: find.byType(Card),
        );
        expect(cardFinder, findsOneWidget);

        final Card cardWidget = tester.widget<Card>(cardFinder);
        final RoundedRectangleBorder shape = cardWidget.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16.0)));
        expect(shape.side.width, equals(2.0));

        // BubblyButton assertions
        // Under Duolingo spirit, depth3d > 0.0 (4.0).
        // This renders the 3D shadow Container AND the button face Container.
        // Therefore, we find exactly 2 Containers inside BubblyButton.
        final bubblyContainersFinder = find.descendant(
          of: find.byType(BubblyButton),
          matching: find.byType(Container),
        );
        expect(bubblyContainersFinder, findsNWidgets(2));

        // --- SWAP TO MINIMALIST SPIRIT ---
        spiritNotifier.toggleSpirit();
        await tester.pumpAndSettle();

        // --- VERIFY MINIMALIST SPIRIT ---
        // StrokeCard assertions (R: 4px, border: 1px)
        final minimalistCardWidget = tester.widget<Card>(cardFinder);
        final RoundedRectangleBorder minimalistShape =
            minimalistCardWidget.shape as RoundedRectangleBorder;
        expect(minimalistShape.borderRadius, equals(BorderRadius.circular(4.0)));
        expect(minimalistShape.side.width, equals(1.0));

        // BubblyButton assertions
        // Under Minimalist spirit, depth3d == 0.0.
        // The 3D shadow Container is omitted. Only the button face Container is rendered.
        // Therefore, we find exactly 1 Container inside BubblyButton.
        expect(bubblyContainersFinder, findsNWidgets(1));
      },
    );
  });
}
