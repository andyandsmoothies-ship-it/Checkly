import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/widgets/metadata_form_card.dart';

void main() {
  group('MetadataFormCard - Accumulation Mode Weighted Scoring UI Tests', () {
    testWidgets(
      'Renders "Weighted Scoring" toggle as enabled and triggers callback for Up/Accumulation mode',
      (tester) async {
        bool isWeightedVal = false;
        bool callbackInvoked = false;

        final titleCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        final categoryTagCtrl = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: titleCtrl,
                  descCtrl: descCtrl,
                  categoryTagCtrl: categoryTagCtrl,
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'up',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: isWeightedVal,
                  onIsWeightedChanged: (val) {
                    isWeightedVal = val;
                    callbackInvoked = true;
                  },
                ),
              ),
            ),
          ),
        );

        // Find the SwitchListTile for Weighted Scoring
        final tileFinder = find.widgetWithText(
          SwitchListTile,
          'Weighted Scoring',
        );
        expect(tileFinder, findsOneWidget);

        // Try to tap the switch or tile to toggle it
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        // Assert callback was triggered and value changed to true
        expect(
          callbackInvoked,
          isTrue,
          reason: 'Callback onIsWeightedChanged should have been invoked.',
        );
        expect(
          isWeightedVal,
          isTrue,
          reason: 'The weighted value should have been updated to true.',
        );
      },
    );
  });
}
