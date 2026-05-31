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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: titleCtrl,
                  descCtrl: descCtrl,
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

    testWidgets(
      'Renders "Audit & Inspection" (down + weighted) info box correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: TextEditingController(),
                  descCtrl: TextEditingController(),
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'down',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: true,
                  onIsWeightedChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Audit & Inspection'), findsOneWidget);
        expect(
          find.textContaining('Deduct Points (Weighted): Start with a perfect 100% score.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders "Basic Checklist" (down + unweighted) info box correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: TextEditingController(),
                  descCtrl: TextEditingController(),
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'down',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: false,
                  onIsWeightedChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Basic Checklist'), findsOneWidget);
        expect(
          find.textContaining('Deduct Points (Simple): Start with a perfect 100% score.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders "Scored Assessment" (up + weighted) info box correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: TextEditingController(),
                  descCtrl: TextEditingController(),
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'up',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: true,
                  onIsWeightedChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Scored Assessment'), findsOneWidget);
        expect(
          find.textContaining('Earn Points (Weighted): Start at 0% score.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders "Simple Scored Assessment" (up + unweighted) info box correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: TextEditingController(),
                  descCtrl: TextEditingController(),
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'up',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: false,
                  onIsWeightedChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Simple Scored Assessment'), findsOneWidget);
        expect(
          find.textContaining('Earn Points (Simple): Start at 0% score.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders "Form & Survey" (none) info box correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MetadataFormCard(
                  titleCtrl: TextEditingController(),
                  descCtrl: TextEditingController(),
                  type: 'qc',
                  onTypeChanged: (_) {},
                  scoreDirection: 'none',
                  onScoreDirectionChanged: (_) {},
                  isWeighted: false,
                  onIsWeightedChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('No Scoring (Survey)'), findsOneWidget);
        expect(
          find.textContaining('No Scoring (Survey): Gather answers without calculating any score.'),
          findsOneWidget,
        );
      },
    );
  });
}
