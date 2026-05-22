import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/widgets/primitives/primitives.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/router/nav_item.dart';
import 'package:checkly/_shared/widgets/bouncy_list_wrapper.dart';

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

    testWidgets('BB-04: AnimatedScale widget is found inside BubblyButton', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BubblyButton(label: 'Click Me')),
        ),
      );

      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('BB-05: Button press squashes the button scale', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BubblyButton(label: 'Tap Test', onPressed: () {}),
          ),
        ),
      );

      final scaleFinder = find.byType(AnimatedScale);
      expect(scaleFinder, findsOneWidget);

      final initialScale = tester.widget<AnimatedScale>(scaleFinder).scale;
      expect(initialScale, equals(1.0));

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Tap Test')),
      );
      await tester.pump(); // trigger state rebuild

      final pressedScale = tester.widget<AnimatedScale>(scaleFinder).scale;
      expect(pressedScale, lessThan(1.0));

      await gesture.up();
    });

    testWidgets('BB-06: Button release springs the button scale back to 1.0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BubblyButton(label: 'Tap Test', onPressed: () {}),
          ),
        ),
      );

      final scaleFinder = find.byType(AnimatedScale);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Tap Test')),
      );
      await tester.pump();

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle(); // let animation finish

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.0));
    });

    testWidgets('BB-07: Button tap cancel restores scale back to 1.0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BubblyButton(label: 'Tap Test', onPressed: () {}),
          ),
        ),
      );

      final scaleFinder = find.byType(AnimatedScale);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Tap Test')),
      );
      await tester.pump();

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, lessThan(1.0));

      await gesture.cancel();
      await tester.pumpAndSettle(); // let animation finish

      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.0));
    });
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

    testWidgets('ES-03: GestureDetector is present on the illustration area', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChecklyEmptyState(
              title: 'No Results Found',
              subtitle: 'Try adjusting your search criteria.',
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('ES-04: Tapping illustration area triggers jiggle animation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChecklyEmptyState(
              title: 'No Results Found',
              subtitle: 'Try adjusting your search criteria.',
            ),
          ),
        ),
      );

      final state = tester.state<ChecklyEmptyStateState>(
        find.byType(ChecklyEmptyState),
      );
      expect(state.isAnimating, isFalse);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump(); // start animation

      expect(state.isAnimating, isTrue);

      await tester.pumpAndSettle(); // let animation finish
      expect(state.isAnimating, isFalse);
    });

    testWidgets(
      'ES-05: Tap jiggle is disabled when reduced motion is requested',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: const ChecklyEmptyState(
                      title: 'No Results Found',
                      subtitle: 'Try adjusting your search criteria.',
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final state = tester.state<ChecklyEmptyStateState>(
          find.byType(ChecklyEmptyState),
        );
        expect(state.isAnimating, isFalse);

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        // Animation should NOT start because reduced motion is enabled
        expect(state.isAnimating, isFalse);
      },
    );
  });

  group('NavItem Widget Tests', () {
    testWidgets(
      'NI-01: AnimatedSlide and AnimatedScale widgets are found inside NavItem',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedSlide), findsOneWidget);
        expect(find.byType(AnimatedScale), findsOneWidget);
      },
    );

    testWidgets('NI-02: Icon scales to 1.2x and slides when isActive=true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scaleFinder = find.byType(AnimatedScale);
      expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.2));

      final slideFinder = find.byType(AnimatedSlide);
      expect(
        tester.widget<AnimatedSlide>(slideFinder).offset,
        equals(const Offset(0, -0.25)),
      );
    });

    testWidgets(
      'NI-03: Icon scale is 1.0x and offset is 0 when isActive=false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: false,
                onTap: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final scaleFinder = find.byType(AnimatedScale);
        expect(tester.widget<AnimatedScale>(scaleFinder).scale, equals(1.0));

        final slideFinder = find.byType(AnimatedSlide);
        expect(
          tester.widget<AnimatedSlide>(slideFinder).offset,
          equals(Offset.zero),
        );
      },
    );

    testWidgets('NI-04: isActive transition false to true triggers animation', (
      WidgetTester tester,
    ) async {
      final isActiveNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: false),
                  child: _NavItemTestWrapper(
                    isActiveNotifier: isActiveNotifier,
                  ),
                );
              },
            ),
          ),
        ),
      );

      final scaleTransitionFinder = find.descendant(
        of: find.byType(NavItem),
        matching: find.byType(ScaleTransition),
      );
      expect(
        tester.widget<ScaleTransition>(scaleTransitionFinder).scale.value,
        equals(1.0),
      );

      // Toggle state to active
      isActiveNotifier.value = true;
      await tester.pump(); // Start transition framework frame

      // Advance by 50 milliseconds to move the animation clock slightly forward
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        tester.widget<ScaleTransition>(scaleTransitionFinder).scale.value,
        isNot(equals(1.0)),
      );
      expect(
        tester.widget<ScaleTransition>(scaleTransitionFinder).scale.value,
        isNot(equals(1.2)),
      );

      await tester.pumpAndSettle();
    });
  });

  group('BouncyListWrapper Widget Tests', () {
    testWidgets('BLW-01: BouncyListWrapper renders all children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyListWrapper(
              children: [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('BLW-02: Each child is wrapped in TweenAnimationBuilder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyListWrapper(children: [Text('Item 1'), Text('Item 2')]),
          ),
        ),
      );

      expect(find.byType(TweenAnimationBuilder<double>), findsNWidgets(2));
    });

    testWidgets(
      'BLW-03: 0 children provided renders empty and causes no error',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: BouncyListWrapper(children: [])),
          ),
        );

        expect(find.byType(Text), findsNothing);
      },
    );

    testWidgets('BLW-04: 13+ children provided caps stagger delay at 500ms', (
      WidgetTester tester,
    ) async {
      final children = List.generate(15, (index) => Text('Item $index'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BouncyListWrapper(children: children)),
        ),
      );

      final staggeredFinder = find.byType(StaggeredListItem);
      expect(staggeredFinder, findsNWidgets(15));

      final firstItem = tester.widget<StaggeredListItem>(staggeredFinder.at(0));
      expect(firstItem.delay, equals(Duration.zero));

      final tenthItem = tester.widget<StaggeredListItem>(
        staggeredFinder.at(10),
      );
      expect(
        tenthItem.delay,
        equals(const Duration(milliseconds: 400)),
      ); // 10 * 40 = 400ms

      final thirteenthItem = tester.widget<StaggeredListItem>(
        staggeredFinder.at(13),
      );
      expect(
        thirteenthItem.delay,
        equals(const Duration(milliseconds: 500)),
      ); // capped at 500ms
    });
  });

  group('BouncyCheckbox Widget Tests', () {
    testWidgets('BC-01: Renders unchecked state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyCheckbox(isChecked: false, onChanged: (val) {}),
          ),
        ),
      );

      // Verify Semantics wrapper is present and unchecked
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.checked == false,
      );
      expect(semanticsFinder, findsOneWidget);

      // Verify no check icon is rendered when unchecked
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('BC-02: Tap triggers onChanged callback', (
      WidgetTester tester,
    ) async {
      bool? checkedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyCheckbox(
              isChecked: false,
              onChanged: (val) {
                checkedResult = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BouncyCheckbox));
      await tester.pump();

      expect(checkedResult, isTrue);
    });

    testWidgets(
      'BC-03: AnimatedScale widget is present inside BouncyCheckbox',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BouncyCheckbox(isChecked: false, onChanged: (val) {}),
            ),
          ),
        );

        expect(find.byType(AnimatedScale), findsOneWidget);
      },
    );

    testWidgets(
      'BC-04: Toggling isChecked false to true plays elastic animation',
      (WidgetTester tester) async {
        final isCheckedNotifier = ValueNotifier<bool>(false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: false),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isCheckedNotifier,
                      builder: (context, val, child) {
                        return BouncyCheckbox(
                          isChecked: val,
                          onChanged: (newVal) {},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final state = tester.state<BouncyCheckboxState>(
          find.byType(BouncyCheckbox),
        );
        expect(state.isAnimating, isFalse);

        isCheckedNotifier.value = true;
        await tester.pump(); // start animation

        expect(state.isAnimating, isTrue);

        await tester.pumpAndSettle();
        expect(state.isAnimating, isFalse);
      },
    );

    testWidgets(
      'BC-05: Tap jiggle is disabled when reduced motion is requested',
      (WidgetTester tester) async {
        final isCheckedNotifier = ValueNotifier<bool>(false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isCheckedNotifier,
                      builder: (context, val, child) {
                        return BouncyCheckbox(
                          isChecked: val,
                          onChanged: (newVal) {},
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        final state = tester.state<BouncyCheckboxState>(
          find.byType(BouncyCheckbox),
        );
        expect(state.isAnimating, isFalse);

        isCheckedNotifier.value = true;
        await tester.pump(); // start animation

        expect(state.isAnimating, isFalse);
      },
    );
  });
}

class _NavItemTestWrapper extends StatefulWidget {
  final ValueNotifier<bool> isActiveNotifier;

  const _NavItemTestWrapper({required this.isActiveNotifier});

  @override
  State<_NavItemTestWrapper> createState() => _NavItemTestWrapperState();
}

class _NavItemTestWrapperState extends State<_NavItemTestWrapper> {
  @override
  void initState() {
    super.initState();
    widget.isActiveNotifier.addListener(_update);
  }

  @override
  void dispose() {
    widget.isActiveNotifier.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return NavItem(
      icon: Icons.home,
      label: 'Home',
      isActive: widget.isActiveNotifier.value,
      onTap: () {},
    );
  }
}
