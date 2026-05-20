import 'package:checkly/features/analytics/manager/analytics_data.dart';
import 'package:checkly/features/analytics/widgets/insights_radar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget(RadarData? radarData) {
    return MaterialApp(
      home: Scaffold(body: InsightsRadarChart(radarData: radarData)),
    );
  }

  testWidgets('FL-05 InsightsRadarChart null data renders empty state', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(null));

    expect(find.text('No regional data yet'), findsOneWidget);
    expect(find.byIcon(Icons.radar), findsOneWidget);
    expect(find.byType(RadarChart), findsNothing);
  });

  testWidgets('FL-06 InsightsRadarChart valid data renders 2 polygons', (
    tester,
  ) async {
    final data = RadarData(
      categories: ['A', 'B', 'C'],
      storeValues: [10.0, 20.0, 30.0],
      regionalValues: [15.0, 25.0, 35.0],
    );

    await tester.pumpWidget(buildTestWidget(data));

    expect(find.text('No regional data yet'), findsNothing);
    expect(find.byType(RadarChart), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
  });
}
