import 'package:checkly/features/analytics/manager/analytics_data.dart';
import 'package:checkly/features/analytics/manager/analytics_manager.dart';
import 'package:checkly/features/analytics/pages/analytics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsManager extends Mock implements AnalyticsManager {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  late MockAnalyticsManager mockManager;

  setUp(() {
    mockManager = MockAnalyticsManager();
    GetIt.I.registerSingleton<AnalyticsManager>(mockManager);

    when(() => mockManager.isLoading).thenReturn(false);
    when(() => mockManager.isOffline).thenReturn(false);
    when(() => mockManager.data).thenReturn(null);
    when(() => mockManager.load()).thenAnswer((_) async {});
    when(() => mockManager.selectedProvince).thenReturn(null);
    when(() => mockManager.selectedStore).thenReturn(null);
    when(() => mockManager.selectedType).thenReturn(null);
    when(() => mockManager.selectedAuditor).thenReturn(null);
    when(() => mockManager.selectedStatus).thenReturn(null);
    when(() => mockManager.selectedReviewStatus).thenReturn(null);
    when(() => mockManager.dateRange).thenReturn('all');
    when(() => mockManager.customDateRange).thenReturn(null);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: Scaffold(body: AnalyticsPage()));
  }

  testWidgets('FL-09 InsightsStale banner shows when stale', (tester) async {
    final data = AnalyticsData(
      totalAudits: 10,
      avgScore: 80.0,
      openAPs: 1,
      overdueAPs: 0,
      completionRate: 100.0,
      trend: [],
      categoryScores: [],
      storeNames: [],
      provinceNames: [],
      templateTypes: [],
      auditorNames: [],
      insightsStale: true,
      insights: [
        ActionableInsight(
          id: '1',
          type: 'info',
          title: 'Stale test',
          description: 'This is a stale insight',
        ),
      ],
      radarData: null,
    );

    when(() => mockManager.data).thenReturn(data);

    await tester.pumpWidget(buildTestWidget());

    // Scroll down to the insights section
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(
      find.text('⚠ Insights last updated over 2 hours ago'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('insights_stale_banner')), findsOneWidget);
  });

  testWidgets('FL-10 No insights when offline', (tester) async {
    final data = AnalyticsData(
      totalAudits: 10,
      avgScore: 80.0,
      openAPs: 1,
      overdueAPs: 0,
      completionRate: 100.0,
      trend: [],
      categoryScores: [],
      storeNames: [],
      provinceNames: [],
      templateTypes: [],
      auditorNames: [],
      insightsStale: false,
      insights: [
        ActionableInsight(
          id: '2',
          type: 'info',
          title: 'Should not show',
          description: 'Offline state',
        ),
      ],
      radarData: null,
    );

    when(() => mockManager.data).thenReturn(data);
    when(() => mockManager.isOffline).thenReturn(true);

    await tester.pumpWidget(buildTestWidget());

    expect(
      find.text('Insights require an internet connection.'),
      findsOneWidget,
    );
    // Insights section is gated by !_manager.isOffline
    expect(find.text('Should not show'), findsNothing);
    expect(find.text('INSIGHTS'), findsNothing);
    expect(find.text('PERFORMANCE RADAR'), findsNothing);
  });
}
