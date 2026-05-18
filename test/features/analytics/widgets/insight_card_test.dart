import 'package:checkly/_shared/theme/app_theme.dart';
import 'package:checkly/features/analytics/manager/analytics_data.dart';
import 'package:checkly/features/analytics/widgets/insight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget(ActionableInsight insight) {
    return MaterialApp(
      home: Scaffold(
        body: InsightCard(insight: insight),
      ),
    );
  }

  testWidgets('FL-01 InsightCard renders warning type', (tester) async {
    final insight = ActionableInsight(
      id: '1',
      type: 'warning',
      title: 'Warning Title',
      description: 'Warning description text',
    );

    await tester.pumpWidget(buildTestWidget(insight));

    expect(find.text('Warning Title'), findsOneWidget);
    expect(find.text('Warning description text'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    
    // The container border
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.color, AppTheme.warning);
  });

  testWidgets('FL-02 InsightCard renders positive type', (tester) async {
    final insight = ActionableInsight(
      id: '2',
      type: 'positive',
      title: 'Positive Title',
      description: 'Positive description text',
    );

    await tester.pumpWidget(buildTestWidget(insight));

    expect(find.text('Positive Title'), findsOneWidget);
    expect(find.text('Positive description text'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.color, AppTheme.success);
  });

  testWidgets('FL-03 InsightCard renders info type', (tester) async {
    final insight = ActionableInsight(
      id: '3',
      type: 'info',
      title: 'Info Title',
      description: 'Info description text',
    );

    await tester.pumpWidget(buildTestWidget(insight));

    expect(find.text('Info Title'), findsOneWidget);
    expect(find.text('Info description text'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.color, AppTheme.info);
  });

}
