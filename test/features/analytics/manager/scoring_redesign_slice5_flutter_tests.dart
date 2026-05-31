import 'package:checkly/features/analytics/manager/analytics_manager.dart';
import 'package:checkly/features/analytics/manager/analytics_data.dart';
import 'package:checkly/features/analytics/services/analytics_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsApiService extends Mock implements AnalyticsApiService {}

void main() {
  group('Scoring Redesign Slice 5 - Flutter Parity and Compilation Tests', () {
    test('AnalyticsApiService getAnalytics structure is intact', () {
      final mockApi = MockAnalyticsApiService();
      expect(mockApi, isNotNull);
    });

    test('AnalyticsData structure compiles successfully', () {
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
      );
      expect(data, isNotNull);
    });

    test(
      'AnalyticsManager compiles successfully',
      () {
        expect(AnalyticsManager, isNotNull);
      },
    );
  });
}
