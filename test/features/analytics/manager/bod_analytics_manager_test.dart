import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/analytics/services/bod_analytics_api_service.dart';
import 'package:checkly/_shared/services/interaction_manager.dart';

class MockBodAnalyticsApiService extends Mock implements BodAnalyticsApiService {}
class MockInteractionManager extends Mock implements InteractionManager {}

void main() {
  late MockBodAnalyticsApiService mockApi;
  late MockInteractionManager mockInteraction;
  late BodAnalyticsManager manager;

  setUp(() {
    mockApi = MockBodAnalyticsApiService();
    mockInteraction = MockInteractionManager();

    final di = GetIt.instance;
    di.pushNewScope();
    di.registerSingleton<InteractionManager>(mockInteraction);

    manager = BodAnalyticsManager(mockApi);
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  final successReport = BodReportResponse(
    chainKpis: const BodChainKpis(totalAudits: 450, avgScore: 84.5, avgTtrDays: 4.2),
    trend: const [],
    topStores: const [],
    bottomStores: const [],
    categoryBreakdown: const [],
    apAging: const BodApAging(bucket0to7: 0, bucket8to30: 0, bucket31to90: 0, bucket90Plus: 0),
    auditorProductivity: const [],
    computedAt: '2026-05-24T02:15:00Z',
    snapshotStatus: 'Complete',
    allowedActions: const ['refresh'],
  );

  final updatedReport = BodReportResponse(
    chainKpis: const BodChainKpis(totalAudits: 451, avgScore: 84.6, avgTtrDays: 4.1),
    trend: const [],
    topStores: const [],
    bottomStores: const [],
    categoryBreakdown: const [],
    apAging: const BodApAging(bucket0to7: 0, bucket8to30: 0, bucket31to90: 0, bucket90Plus: 0),
    auditorProductivity: const [],
    computedAt: '2026-05-24T02:20:00Z', // Updated timestamp
    snapshotStatus: 'Complete',
    allowedActions: const ['refresh'],
  );

  group('BodAnalyticsManager Unit Tests', () {
    test('TC-BOD-INIT-01: Verify initial manager state values', () {
      expect(manager.isLoading, isFalse);
      expect(manager.isOffline, isFalse);
      expect(manager.isEmpty, isFalse);
      expect(manager.error, isNull);
      expect(manager.report, isNull);
    });

    test('TC-BOD-LOAD-01: Successful report retrieval flow', () async {
      when(() => mockApi.getReport()).thenAnswer((_) async => successReport);

      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      final future = manager.loadReport();

      expect(manager.isLoading, isTrue);
      expect(manager.isOffline, isFalse);
      expect(manager.isEmpty, isFalse);

      await future;

      expect(manager.isLoading, isFalse);
      expect(manager.report, equals(successReport));
      expect(manager.error, isNull);
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('TC-BOD-LOAD-02: Report 404 sets isEmpty to true', () async {
      when(() => mockApi.getReport()).thenThrow(Exception('404 Not Found'));

      await manager.loadReport();

      expect(manager.isLoading, isFalse);
      expect(manager.isEmpty, isTrue);
      expect(manager.report, isNull);
    });

    test('TC-BOD-LOAD-03: Dio connection exception triggers offline state', () async {
      when(() => mockApi.getReport()).thenThrow(Exception('DioException: connection error'));

      await manager.loadReport();

      expect(manager.isLoading, isFalse);
      expect(manager.isOffline, isTrue);
      expect(manager.report, isNull);
    });

    test('TC-BOD-LOAD-04: Generic error triggers generic message mapping', () async {
      when(() => mockApi.getReport()).thenThrow(Exception('500 Internal Server Error'));

      await manager.loadReport();

      expect(manager.isLoading, isFalse);
      expect(manager.error, equals('Something went wrong. Please try again.'));
      expect(manager.report, isNull);
    });

    test('TC-BOD-REFRESH-01: Success refresh starts polling and stops on new computedAt', () {
      fakeAsync((async) {
        // Initial setup: manager already has a report
        when(() => mockApi.getReport()).thenAnswer((_) async => successReport);
        async.elapse(Duration.zero);
        manager.loadReport();
        async.elapse(Duration.zero);

        expect(manager.report, equals(successReport));

        // Stub triggerRefresh to return success response
        when(() => mockApi.triggerRefresh()).thenAnswer((_) async => {'status': 'Accepted'});

        // Dynamic API response for subsequent GET calls:
        // Returns original report for the first 2 polls, then the updated report.
        int callCount = 0;
        when(() => mockApi.getReport()).thenAnswer((_) async {
          callCount++;
          if (callCount < 3) {
            return successReport;
          } else {
            return updatedReport;
          }
        });

        // Act
        clearInteractions(mockApi);
        manager.refreshReport();
        
        // Assert refresh puts manager into loading state
        expect(manager.isLoading, isTrue);

        // Advance 4 seconds (less than 5s interval): no calls yet
        async.elapse(const Duration(seconds: 4));
        verifyNever(() => mockApi.getReport());

        // Advance to 5s: first poll completes (returns old data, polling continues)
        async.elapse(const Duration(seconds: 1));
        verify(() => mockApi.getReport()).called(1);
        expect(manager.isLoading, isTrue);

        // Advance to 10s: second poll completes (returns old data, polling continues)
        async.elapse(const Duration(seconds: 5));
        verify(() => mockApi.getReport()).called(1);
        expect(manager.isLoading, isTrue);

        // Advance to 15s: third poll completes (returns updated data, polling should stop)
        async.elapse(const Duration(seconds: 5));
        verify(() => mockApi.getReport()).called(1);

        // Post-poll state
        expect(manager.isLoading, isFalse);
        expect(manager.report, equals(updatedReport));
        expect(manager.error, isNull);
      });
    });

    test('TC-BOD-REFRESH-02: Polling times out after 60 seconds (12 checks) and shows warning toast', () {
      fakeAsync((async) {
        when(() => mockApi.getReport()).thenAnswer((_) async => successReport);
        manager.loadReport();
        async.elapse(Duration.zero);

        when(() => mockApi.triggerRefresh()).thenAnswer((_) async => {'status': 'Accepted'});
        when(() => mockApi.getReport()).thenAnswer((_) async => successReport); // Constant old report
        when(() => mockInteraction.showWarningToast(any())).thenReturn(null);

        // Act
        clearInteractions(mockApi);
        manager.refreshReport();

        expect(manager.isLoading, isTrue);

        // Elapse 59 seconds: 11 polls triggered
        async.elapse(const Duration(seconds: 59));
        verify(() => mockApi.getReport()).called(11);
        expect(manager.isLoading, isTrue);

        // Elapse 1 more second (total 60s): 12th poll triggered, timeout hits
        async.elapse(const Duration(seconds: 1));
        verify(() => mockApi.getReport()).called(1);
        
        expect(manager.isLoading, isFalse);
        expect(manager.report, equals(successReport)); // Reverts to original report
        verify(() => mockInteraction.showWarningToast(
          'Data computation is taking longer than expected. Please check back shortly.',
        )).called(1);
      });
    });

    test('TC-BOD-REFRESH-03: HTTP 429 rate limit triggers toast and skips polling', () {
      fakeAsync((async) {
        when(() => mockApi.getReport()).thenAnswer((_) async => successReport);
        manager.loadReport();
        async.elapse(Duration.zero);

        when(() => mockApi.triggerRefresh()).thenThrow(Exception('429 Too Many Requests'));
        when(() => mockInteraction.showWarningToast(any())).thenReturn(null);

        clearInteractions(mockApi);
        manager.refreshReport();

        // Should not enter loading/polling state, show warning toast immediately
        expect(manager.isLoading, isFalse);
        verify(() => mockInteraction.showWarningToast(
          'Rate limit exceeded. Please try again later.',
        )).called(1);
        verifyNever(() => mockApi.getReport());
      });
    });

    test('TC-BOD-REFRESH-04: Refresh in live/filtered mode fetches filtered report and bypasses server triggers', () {
      fakeAsync((async) {
        // Apply filter to enter live/filtered mode
        when(() => mockApi.getFilteredReport('Hanoi', '')).thenAnswer((_) async => updatedReport);
        manager.applyFilter('Hanoi', '');
        async.elapse(Duration.zero);

        expect(manager.isLiveMode, isTrue);
        expect(manager.activeProvince, equals('Hanoi'));

        // Reset mocks and setup for refresh
        clearInteractions(mockApi);
        when(() => mockApi.getFilteredReport('Hanoi', '')).thenAnswer((_) async => updatedReport);

        // Act
        manager.refreshReport();
        async.elapse(Duration.zero);

        // Assert: refresh handles dynamic query synchronously and never calls triggerRefresh
        expect(manager.isLoading, isFalse);
        expect(manager.report, equals(updatedReport));
        verify(() => mockApi.getFilteredReport('Hanoi', '')).called(1);
        verifyNever(() => mockApi.triggerRefresh());
      });
    });

    group('Slice 2 - Drilldown Client Bridge Tests', () {
      final mockApEntry = ApDetailEntry(
        id: '11111111-2222-3333-4444-555555555555',
        criteriaLabel: 'Temperature Logs',
        storeName: 'Central Market',
        managerName: 'Andy Manager',
        ageInDays: 12,
      );

      final mockStoreSummary = StoreBodSummary(
        storeName: 'Central Store',
        recentAudits: [
          RecentAuditEntry(date: '2026-05-25T00:00:00Z', score: 85.0, auditorName: 'Alice')
        ],
        categoryBreakdown: [
          CategoryScoreEntry(categoryName: 'Safety', avgScore: 90.0)
        ],
      );

      final mockCategoryStoreEntry = CategoryStoreEntry(
        storeName: 'Store A',
        avgScore: 82.5,
        auditCount: 10,
        failureCount: 2,
      );

      test('TC-BOD-AP-01: loadApDetails maps display names to normalized strings case-insensitively with trim', () async {
        when(() => mockApi.getApBucketDetail('0-7d')).thenAnswer((_) async => [mockApEntry]);
        when(() => mockApi.getApBucketDetail('8-30d')).thenAnswer((_) async => [mockApEntry]);
        when(() => mockApi.getApBucketDetail('31-90d')).thenAnswer((_) async => [mockApEntry]);
        when(() => mockApi.getApBucketDetail('90d+')).thenAnswer((_) async => [mockApEntry]);

        await manager.loadApDetails('0-7 Days');
        verify(() => mockApi.getApBucketDetail('0-7d')).called(1);

        await manager.loadApDetails('  8-30 days  ');
        verify(() => mockApi.getApBucketDetail('8-30d')).called(1);

        await manager.loadApDetails('31-90 Days');
        verify(() => mockApi.getApBucketDetail('31-90d')).called(1);

        await manager.loadApDetails('90+ Days');
        verify(() => mockApi.getApBucketDetail('90d+')).called(1);
      });

      test('TC-BOD-AP-02: loadApDetails concurrency check ignores double-clicks', () async {
        when(() => mockApi.getApBucketDetail(any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return [mockApEntry];
        });

        // Trigger two loads concurrently
        final firstCall = manager.loadApDetails('8-30 Days');
        final secondCall = manager.loadApDetails('8-30 Days');

        await Future.wait([firstCall, secondCall]);

        // Verify API was called only once due to concurrency block
        verify(() => mockApi.getApBucketDetail('8-30d')).called(1);
      });

      test('TC-BOD-AP-03: loadApDetails success path populates data and resets error state', () async {
        when(() => mockApi.getApBucketDetail('8-30d')).thenAnswer((_) async => [mockApEntry]);

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        final future = manager.loadApDetails('8-30 Days');

        expect(manager.isApDetailLoading, isTrue);

        await future;

        expect(manager.isApDetailLoading, isFalse);
        expect(manager.apDetails, equals([mockApEntry]));
        expect(manager.error, isNull);
        expect(notifyCount, greaterThanOrEqualTo(2));
      });

      test('TC-BOD-AP-04: loadApDetails error path resets list and maps error', () async {
        when(() => mockApi.getApBucketDetail(any())).thenThrow(Exception('DioException: timeout'));

        await manager.loadApDetails('8-30 Days');

        expect(manager.isApDetailLoading, isFalse);
        expect(manager.apDetails, isEmpty);
        expect(manager.error, equals('Something went wrong. Please try again.'));
      });

      test('TC-BOD-AP-05: loadApDetails with All or empty bucket name fetches all aging buckets and sorts them by age descending', () async {
        final entry1 = ApDetailEntry(id: '1', criteriaLabel: 'A', storeName: 'S', managerName: 'M', ageInDays: 5);
        final entry2 = ApDetailEntry(id: '2', criteriaLabel: 'B', storeName: 'S', managerName: 'M', ageInDays: 15);
        final entry3 = ApDetailEntry(id: '3', criteriaLabel: 'C', storeName: 'S', managerName: 'M', ageInDays: 25);
        final entry4 = ApDetailEntry(id: '4', criteriaLabel: 'D', storeName: 'S', managerName: 'M', ageInDays: 45);

        when(() => mockApi.getApBucketDetail('0-7d')).thenAnswer((_) async => [entry1]);
        when(() => mockApi.getApBucketDetail('8-30d')).thenAnswer((_) async => [entry2]);
        when(() => mockApi.getApBucketDetail('31-90d')).thenAnswer((_) async => [entry3]);
        when(() => mockApi.getApBucketDetail('90d+')).thenAnswer((_) async => [entry4]);

        await manager.loadApDetails('All');

        verify(() => mockApi.getApBucketDetail('0-7d')).called(1);
        verify(() => mockApi.getApBucketDetail('8-30d')).called(1);
        verify(() => mockApi.getApBucketDetail('31-90d')).called(1);
        verify(() => mockApi.getApBucketDetail('90d+')).called(1);

        expect(manager.isApDetailLoading, isFalse);
        expect(manager.apDetails.length, equals(4));
        expect(manager.apDetails[0].ageInDays, equals(45));
        expect(manager.apDetails[1].ageInDays, equals(25));
        expect(manager.apDetails[2].ageInDays, equals(15));
        expect(manager.apDetails[3].ageInDays, equals(5));
      });

      test('TC-BOD-STORE-01: loadStoreDetail success fetches and populates storeDetail', () async {
        when(() => mockApi.getStoreBodSummary('store-1')).thenAnswer((_) async => mockStoreSummary);

        final future = manager.loadStoreDetail('store-1');

        expect(manager.isStoreDetailLoading, isTrue);

        await future;

        expect(manager.isStoreDetailLoading, isFalse);
        expect(manager.storeDetail, equals(mockStoreSummary));
        expect(manager.error, isNull);
      });

      test('TC-BOD-STORE-02: loadStoreDetail error resets detail and populates error message', () async {
        when(() => mockApi.getStoreBodSummary('store-1')).thenThrow(Exception('500 Server Error'));

        await manager.loadStoreDetail('store-1');

        expect(manager.isStoreDetailLoading, isFalse);
        expect(manager.storeDetail, isNull);
        expect(manager.error, equals('Something went wrong. Please try again.'));
      });

      test('TC-BOD-CAT-01: loadCategoryDetail trims category name and fetches worst category stores list', () async {
        when(() => mockApi.getCategoryDetail('Food Safety')).thenAnswer((_) async => [mockCategoryStoreEntry]);

        await manager.loadCategoryDetail('  Food Safety  ');

        expect(manager.isCategoryDetailLoading, isFalse);
        expect(manager.categoryDetail, equals([mockCategoryStoreEntry]));
        expect(manager.error, isNull);
        verify(() => mockApi.getCategoryDetail('Food Safety')).called(1);
      });

      test('TC-BOD-AUD-01: loadAuditorDetail filters auditor productivity details client-side', () async {
        final mockAuditor1 = {
          'auditorId': 'auditor-1',
          'auditorName': 'Alice Auditor',
          'completedAudits': 5,
          'avgScore': 88.0,
        };
        final mockAuditor2 = {
          'auditorId': 'auditor-2',
          'auditorName': 'Bob Auditor',
          'completedAudits': 12,
          'avgScore': 91.5,
        };

        when(() => mockApi.getAuditorProductivity()).thenAnswer((_) async => [mockAuditor1, mockAuditor2]);

        final future = manager.loadAuditorDetail('Bob Auditor');

        expect(manager.isAuditorDetailLoading, isTrue);

        await future;

        expect(manager.isAuditorDetailLoading, isFalse);
        expect(manager.auditorDetail, equals(mockAuditor2));
        expect(manager.error, isNull);
      });
    });
  });
}

