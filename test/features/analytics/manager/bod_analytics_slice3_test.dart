import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/analytics/services/bod_analytics_api_service.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
// Note: We anticipate this helper in Slice 3 for TC-12 compliance
import 'package:checkly/features/analytics/utils/trend_utils.dart';

class MockBodAnalyticsApiService extends Mock
    implements BodAnalyticsApiService {}

class MockErrorDisplayService extends Mock implements ErrorDisplayService {}

void main() {
  late MockBodAnalyticsApiService mockApi;
  late MockErrorDisplayService mockErrorDisplay;
  late BodAnalyticsManager manager;

  setUp(() {
    mockApi = MockBodAnalyticsApiService();
    mockErrorDisplay = MockErrorDisplayService();

    final di = GetIt.instance;
    di.pushNewScope();
    di.registerSingleton<ErrorDisplayService>(mockErrorDisplay);

    manager = BodAnalyticsManager(mockApi);
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  group('Slice 3 - Dart Typed Model Parity (TC-04)', () {
    test('Should parse fully typed BodReportResponse from valid JSON', () {
      final jsonPayload = {
        'chainKpis': {'totalAudits': 42, 'avgScore': 78.5, 'avgTtrDays': 4.2},
        'trend': [
          {'month': '2026-05', 'avgScore': 78.5},
        ],
        'topStores': [
          {
            'storeId': 'store-1',
            'storeName': 'Hoan Kiem',
            'avgScore': 91.2,
            'auditCount': 5,
            'lastSyncedAt': '2026-05-24T10:00:00Z',
          },
        ],
        'bottomStores': [],
        'categoryBreakdown': [],
        'apAging': {
          'bucket0to30': 5,
          'bucket31to60': 2,
          'bucket61to90': 1,
          'bucket90Plus': 3,
        },
        'auditorProductivity': [],
        'computedAt': '2026-05-24T15:00:00Z',
        'snapshotStatus': 'Complete',
        'allowedActions': ['refresh'],
        'isLiveData': true,
        'goldenStore': {
          'storeId': 'flagship-1',
          'storeName': 'Siam Square',
          'avgScore': 96.5,
        },
      };

      // Act
      final response = BodReportResponse.fromJson(jsonPayload);

      // Assert: Verify fully typed fields (TC-04 & Golden Store/TTR mapping)
      expect(response.chainKpis.totalAudits, equals(42));
      expect(response.chainKpis.avgScore, equals(78.5));
      expect(response.chainKpis.avgTtrDays, equals(4.2));

      expect(response.topStores.first.storeId, equals('store-1'));
      expect(response.topStores.first.lastSyncedAt, isNotNull);
      expect(response.topStores.first.lastSyncedAt!.year, equals(2026));

      expect(response.goldenStore, isNotNull);
      expect(response.goldenStore!.storeName, equals('Siam Square'));
      expect(response.goldenStore!.avgScore, equals(96.5));
    });

    test(
      'Should parse gracefully with null GoldenStore and default values (Gap Analysis AC)',
      () {
        final jsonPayload = {
          'chainKpis': {'totalAudits': 0, 'avgScore': 0.0, 'avgTtrDays': 0.0},
          'trend': [],
          'topStores': [],
          'bottomStores': [],
          'categoryBreakdown': [],
          'apAging': {},
          'auditorProductivity': [],
          'computedAt': '',
          'snapshotStatus': '',
          'allowedActions': [],
          'goldenStore': null, // Null golden store safety check
        };

        // Act
        final response = BodReportResponse.fromJson(jsonPayload);

        // Assert
        expect(response.goldenStore, isNull);
        expect(response.chainKpis.avgTtrDays, equals(0.0));
      },
    );
  });

  group('Slice 3 - Manager Filter State & Concurrency Control', () {
    final mockReport = BodReportResponse(
      chainKpis: BodChainKpis(totalAudits: 10, avgScore: 80.0, avgTtrDays: 2.5),
      trend: [],
      topStores: [],
      bottomStores: [],
      categoryBreakdown: [],
      apAging: BodApAging(
        bucket0to7: 0,
        bucket8to30: 0,
        bucket31to90: 0,
        bucket90Plus: 0,
      ),
      auditorProductivity: [],
      computedAt: '2026-05-24T15:00:00Z',
      snapshotStatus: 'Complete',
      allowedActions: [],
      goldenStore: null,
    );

    test(
      'applyFilter and clearFilter update active states and load filtered report',
      () async {
        when(
          () => mockApi.getFilteredReport(any(), any()),
        ).thenAnswer((_) async => mockReport);
        when(() => mockApi.getReport()).thenAnswer((_) async => mockReport);

        // Act: Apply Filter
        final future = manager.applyFilter('Hanoi', 'Hoan Kiem');

        expect(manager.isLoading, isTrue);
        expect(manager.isLiveMode, isTrue);
        expect(manager.activeProvince, equals('Hanoi'));
        expect(manager.activeDistrict, equals('Hoan Kiem'));

        await future;

        expect(manager.isLoading, isFalse);
        verify(() => mockApi.getFilteredReport('Hanoi', 'Hoan Kiem')).called(1);

        // Act: Clear Filter
        final clearFuture = manager.clearFilter();
        expect(manager.isLiveMode, isFalse);
        expect(manager.activeProvince, isNull);
        expect(manager.activeDistrict, isNull);

        await clearFuture;
        verify(() => mockApi.getReport()).called(1);
      },
    );

    test(
      'applyFilter concurrency guard ignores concurrent requests while loading (Gap Analysis AC)',
      () async {
        when(() => mockApi.getFilteredReport(any(), any())).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockReport;
        });

        // Call applyFilter twice concurrently
        final f1 = manager.applyFilter('Hanoi', 'Hoan Kiem');
        final f2 = manager.applyFilter('Hanoi', 'Ba Dinh'); // Should be ignored

        await Future.wait([f1, f2]);

        // Verify getFilteredReport was only called once for the first filter
        verify(() => mockApi.getFilteredReport('Hanoi', 'Hoan Kiem')).called(1);
        verifyNever(() => mockApi.getFilteredReport('Hanoi', 'Ba Dinh'));
      },
    );
  });

  group('Slice 3 - Smooth Trend Curve (TC-12)', () {
    test('SMA3 calculations are accurate for normal data series', () {
      final scores = [81.0, 83.2, 82.5, 85.0];

      // Index 2 (3rd month): (81.0 + 83.2 + 82.5) / 3 = 82.2333...
      final sma3Month3 = TrendUtils.calculateSMA3(scores, 2);
      expect(sma3Month3, closeTo(82.23, 0.01));

      // Index 3 (4th month): (83.2 + 82.5 + 85.0) / 3 = 83.5666...
      final sma3Month4 = TrendUtils.calculateSMA3(scores, 3);
      expect(sma3Month4, closeTo(83.57, 0.01));
    });

    test(
      'SMA3 defaults to raw score for index < 2 or empty data series (Gap Analysis AC)',
      () {
        final scores = [81.0, 83.2];

        expect(TrendUtils.calculateSMA3(scores, 0), equals(81.0));
        expect(TrendUtils.calculateSMA3(scores, 1), equals(83.2));
        expect(TrendUtils.calculateSMA3([], 0), equals(0.0));
      },
    );
  });
}
