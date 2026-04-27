import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/features/templates/widgets/advanced_settings_card.dart';

void main() {
  group('AdvancedSettingsCard - Require Confirmation UI Tests', () {
    testWidgets('Renders "Require Confirmation" toggle and triggers callback', (
      tester,
    ) async {
      bool changedValue = false;
      final deadlineCtrl = TextEditingController(text: '7');
      final reminderCtrl = TextEditingController(text: '2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdvancedSettingsCard(
                scoringMode: 'penalty',
                ccpOverride: false,
                riskOverride: false,
                weightedDensity: false,
                progressiveRepeat: false,
                confirmRequired: false,
                deadlineCtrl: deadlineCtrl,
                reminderCtrl: reminderCtrl,
                onCcpChanged: (_) {},
                onRiskChanged: (_) {},
                onDensityChanged: (_) {},
                onProgressiveChanged: (_) {},
                onConfirmChanged: (val) {
                  changedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      // Expand the settings card
      await tester.tap(find.text('Advanced Settings'));
      await tester.pumpAndSettle();

      // Assert that the new UI tile exists
      final confirmTileFinder = find.text('Require Confirmation');
      expect(
        confirmTileFinder,
        findsOneWidget,
        reason: 'The Require Confirmation text should be rendered.',
      );

      // Find the switch associated with the Require Confirmation tile.
      // Since it's an ExpandableSettingTile, we can tap the text to toggle it.
      await tester.tap(confirmTileFinder);
      await tester.pumpAndSettle();

      // Assert callback was triggered with true
      expect(
        changedValue,
        isTrue,
        reason: 'Tapping the tile should invoke onConfirmChanged with true.',
      );
    });

    testWidgets('Renders toggle in ON state when confirmRequired is true', (
      tester,
    ) async {
      final deadlineCtrl = TextEditingController(text: '7');
      final reminderCtrl = TextEditingController(text: '2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdvancedSettingsCard(
                scoringMode: 'penalty',
                ccpOverride: false,
                riskOverride: false,
                weightedDensity: false,
                progressiveRepeat: false,
                confirmRequired: true,
                deadlineCtrl: deadlineCtrl,
                reminderCtrl: reminderCtrl,
                onCcpChanged: (_) {},
                onRiskChanged: (_) {},
                onDensityChanged: (_) {},
                onProgressiveChanged: (_) {},
                onConfirmChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Advanced Settings'));
      await tester.pumpAndSettle();

      final confirmTileFinder = find.text('Require Confirmation');
      expect(confirmTileFinder, findsOneWidget);

      // Verify the switch is ON. ExpandableSettingTile uses a Switch internally.
      // A quick way is to check the Switch's value.
      final tileFinder = find.widgetWithText(
        SwitchListTile,
        'Require Confirmation',
      );
      final switchFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(switchFinder.first).value, isTrue);
    });
  });
}
