import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/analytics/widgets/bod_kpi_grid.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';

class MockBodAnalyticsManager extends Mock implements BodAnalyticsManager {}

void main() {
  late MockBodAnalyticsManager mockManager;

  setUp(() {
    mockManager = MockBodAnalyticsManager();
    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
  });

  Widget buildTestWidget({
    required Map<String, dynamic> chainKpis,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BodKpiGrid(
            chainKpis: chainKpis,
            trend: const [],
            manager: mockManager,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders Geofence Bypasses card with count when geofenceBypassCount is provided',
    (tester) async {
      // Arrange: Seed KPIs containing geofenceBypassCount = 5
      final chainKpis = {
        'totalAudits': 45,
        'avgScore': 84.5,
        'completionRate': 92.5,
        'openAPs': 12,
        'overdueAPs': 3,
        'activeStores': 8,
        'totalAuditors': 4,
        'avgTtrDays': 5.5,
        'geofenceBypassCount': 5,
      };

      // Act: Pump the KPI Grid widget
      await tester.pumpWidget(buildTestWidget(chainKpis: chainKpis));
      await tester.pumpAndSettle();

      // Assert: Verify "Geofence Bypasses" is rendered with correct count
      expect(find.text('Geofence Bypasses'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    },
  );

  testWidgets(
    'renders Geofence Bypasses card with 0 when geofenceBypassCount is missing or null',
    (tester) async {
      // Arrange: Seed KPIs with missing/null geofenceBypassCount
      final chainKpis = {
        'totalAudits': 10,
        'avgScore': 75.0,
        'completionRate': 50.0,
        'openAPs': 1,
        'overdueAPs': 0,
        'activeStores': 2,
        'totalAuditors': 1,
        'avgTtrDays': 2.0,
      };

      // Act: Pump the KPI Grid widget
      await tester.pumpWidget(buildTestWidget(chainKpis: chainKpis));
      await tester.pumpAndSettle();

      // Assert: Verify "Geofence Bypasses" is rendered with default 0
      expect(find.text('Geofence Bypasses'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    },
  );
}
