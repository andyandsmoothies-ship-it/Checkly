import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart';
import 'package:checkly/features/analytics/widgets/area_bod_ap_bucket_detail_sheet.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/area_bod_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';

class MockBodAnalyticsManager extends Mock implements BodAnalyticsManager {}
class MockAreaBodManager extends Mock implements AreaBodManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(BodAgingBucket.all);
  });

  late MockBodAnalyticsManager mockBodManager;
  late MockAreaBodManager mockAreaManager;

  setUp(() {
    mockBodManager = MockBodAnalyticsManager();
    when(() => mockBodManager.addListener(any())).thenReturn(null);
    when(() => mockBodManager.removeListener(any())).thenReturn(null);

    mockAreaManager = MockAreaBodManager();
    when(() => mockAreaManager.addListener(any())).thenReturn(null);
    when(() => mockAreaManager.removeListener(any())).thenReturn(null);
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('BodApBucketDetailSheet Scroll Physics Tests', () {
    testWidgets('BodApBucketDetailSheet ListView scroll physics is NeverScrollableScrollPhysics', (tester) async {
      final mockData = [
        ApDetailEntry(
          id: 'ap-1',
          criteriaLabel: 'Temperature Check',
          storeName: 'Tan Binh',
          managerName: 'Manager A',
          ageInDays: 45,
        ),
      ];

      when(() => mockBodManager.loadApDetails(any())).thenAnswer((_) async {});
      when(() => mockBodManager.isApDetailLoading).thenReturn(false);
      when(() => mockBodManager.apDetails).thenReturn(mockData);

      await tester.pumpWidget(
        buildTestWidget(
          BodApBucketDetailSheet(
            bucket: BodAgingBucket.all,
            manager: mockBodManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });

  group('AreaBodApBucketDetailSheet Scroll Physics Tests', () {
    testWidgets('AreaBodApBucketDetailSheet ListView scroll physics is NeverScrollableScrollPhysics', (tester) async {
      final mockData = [
        ApDetailEntry(
          id: 'ap-2',
          criteriaLabel: 'Hygiene Audit',
          storeName: 'Go Vap',
          managerName: 'Manager B',
          ageInDays: 32,
        ),
      ];

      when(() => mockAreaManager.loadApDetails(any())).thenAnswer((_) async {});
      when(() => mockAreaManager.isApDetailLoading).thenReturn(false);
      when(() => mockAreaManager.apDetails).thenReturn(mockData);

      await tester.pumpWidget(
        buildTestWidget(
          AreaBodApBucketDetailSheet(
            bucket: BodAgingBucket.all,
            manager: mockAreaManager,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
