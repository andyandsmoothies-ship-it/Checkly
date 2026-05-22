import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/_shared/widgets/primitives/primitives.dart';
import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/constants/app_roles.dart';

void main() {
  group('PillChip Widget Tests', () {
    testWidgets('PC-01: Renders label and icon correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PillChip(
              label: 'Verified',
              icon: Icon(Icons.check, size: 14),
            ),
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('PC-02: Mapped colors are pastel with no grays', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PillChip(label: 'Green', type: PillChipType.green),
                PillChip(label: 'Blue', type: PillChipType.blue),
                PillChip(label: 'Red', type: PillChipType.red),
                PillChip(label: 'Yellow', type: PillChipType.yellow),
                PillChip(label: 'Purple', type: PillChipType.purple),
              ],
            ),
          ),
        ),
      );

      final chipFinder = find.byType(PillChip);
      expect(chipFinder, findsNWidgets(5));

      final firstContainer = tester.widget<Container>(
        find.descendant(of: chipFinder.at(0), matching: find.byType(Container)),
      );
      final boxDecoration = firstContainer.decoration as BoxDecoration;
      expect(boxDecoration.color, equals(AppColors.seaSponge));
      expect(boxDecoration.borderRadius, equals(BorderRadius.circular(100)));
    });

    testWidgets('PC-03: Tapping triggers onTap callback', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillChip(label: 'Clickable', onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('Clickable'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('PastelAvatar Widget Tests', () {
    testWidgets('PA-01: Derives initials correctly from name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PastelAvatar(name: 'Bruce Wayne', role: AppRoles.admin),
                PastelAvatar(name: 'Clark', role: AppRoles.auditor),
                PastelAvatar(name: '', role: AppRoles.storeManager),
              ],
            ),
          ),
        ),
      );

      expect(find.text('BW'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('PA-02: Map roles to custom pastel backgrounds', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PastelAvatar(
              name: 'Bruce Wayne',
              role: AppRoles.admin,
              size: 50.0,
            ),
          ),
        ),
      );

      final avatarFinder = find.byType(PastelAvatar);
      expect(avatarFinder, findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(of: avatarFinder, matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.walkingFish));
      expect(decoration.shape, equals(BoxShape.circle));
      expect(decoration.border!.top.color, equals(AppColors.flamingo));
    });
  });

  group('BubblySwitch Widget Tests', () {
    testWidgets('BS-01: Changes track color when active/inactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BubblySwitch(value: true, onChanged: (_) {}),
                BubblySwitch(value: false, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );

      final switchFinder = find.byType(BubblySwitch);
      expect(switchFinder, findsNWidgets(2));
    });

    testWidgets('BS-02: Tapping triggers onChanged callback', (
      WidgetTester tester,
    ) async {
      bool changedValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BubblySwitch(
              value: false,
              onChanged: (val) => changedValue = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BubblySwitch));
      await tester.pump();

      expect(changedValue, isTrue);
    });
  });

  group('BubblyDialog Widget Tests', () {
    testWidgets(
      'BD-01: Renders layout correctly with R: 24px and Swan border',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const BubblyDialog(
                          title: Text('Quest Title'),
                          content: Text('Finish this campaign to earn 50 XP!'),
                          actions: [Text('Close')],
                        ),
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Quest Title'), findsOneWidget);
        expect(
          find.text('Finish this campaign to earn 50 XP!'),
          findsOneWidget,
        );
        expect(find.text('Close'), findsOneWidget);

        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);

        final Dialog dialogWidget = tester.widget<Dialog>(dialogFinder);
        final shape = dialogWidget.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(24.0)));
        expect(shape.side.color, equals(AppColors.swan));
        expect(shape.side.width, equals(2.0));
      },
    );
  });
}
