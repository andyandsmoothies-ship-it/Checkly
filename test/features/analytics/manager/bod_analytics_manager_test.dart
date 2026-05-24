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
    chainKpis: {'totalAudits': 450, 'avgScore': 84.5},
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: {},
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z',
    snapshotStatus: 'Complete',
    allowedActions: ['refresh'],
  );

  final updatedReport = BodReportResponse(
    chainKpis: {'totalAudits': 451, 'avgScore': 84.6},
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: {},
    auditorProductivity: [],
    computedAt: '2026-05-24T02:20:00Z', // Updated timestamp
    snapshotStatus: 'Complete',
    allowedActions: ['refresh'],
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
  });
}
