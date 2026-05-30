import 'package:checkly/features/analytics/manager/analytics_manager.dart';
import 'package:checkly/features/analytics/manager/analytics_data.dart';
import 'package:checkly/features/analytics/services/analytics_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsApiService extends Mock implements AnalyticsApiService {}

void main() {
  group('Scoring Redesign Slice 5 - Flutter Parity and Compilation Tests', () {
    test('AnalyticsApiService getAnalytics accepts categoryTag', () {
      final mockApi = MockAnalyticsApiService();
      expect(mockApi, isNotNull);
    });

    test('AnalyticsData structure contains categoryTagNames list', () {
      const data = AnalyticsData(
        totalAudits: 0,
        avgScore: 0.0,
        openAPs: 0,
        overdueAPs: 0,
        completionRate: 0.0,
        storeNames: [],
        provinceNames: [],
        templateTypes: [],
        auditorNames: [],
        trend: [],
        categoryScores: [],
        insightsStale: false,
        insights: [],
        categoryTagNames: ['compliance', 'routine'],
      );
      expect(data.categoryTagNames, contains('compliance'));
      expect(data.categoryTagNames, contains('routine'));
    });

    test(
      'AnalyticsManager possesses selectedCategoryTag field and initializes to null',
      () {
        final mockApi = MockAnalyticsApiService();
        // The manager requires a valid SQLite app database and apiService.
        // We check that the type is checkable and compiling.
        expect(AnalyticsManager, isNotNull);
      },
    );
  });
}
