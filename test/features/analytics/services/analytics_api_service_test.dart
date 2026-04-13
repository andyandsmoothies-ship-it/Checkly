import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/features/analytics/services/analytics_api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late AnalyticsApiService service;
  late MockDio dio;

  setUp(() {
    dio = MockDio();
    service = AnalyticsApiService(dio);
  });

  group('AnalyticsApiService —', () {
    test('getAnalytics maps query parameters correctly and returns data', () async {
      // Arrange
      final mockData = <String, dynamic>{'total_audits': 10, 'average_score': 85.5};
      
      when(() => dio.get(
        '/analytics',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/analytics'),
          statusCode: 200,
          data: mockData,
        ),
      );

      // Act
      final result = await service.getAnalytics(
        storeId: 's1',
        areaId: 'a1',
        startDate: '2026-01-01',
        endDate: '2026-01-31',
      );

      // Assert
      expect(result, equals(mockData));
      
      // Verify parameters were mapped
      final captured = verify(() => dio.get(
        '/analytics',
        queryParameters: captureAny(named: 'queryParameters'),
      )).captured;
      final params = captured.first as Map<String, dynamic>;
      
      expect(params['storeId'], 's1');
      expect(params['areaId'], 'a1');
      expect(params['startDate'], '2026-01-01');
      expect(params['endDate'], '2026-01-31');
    });

    test('getAnalytics omits null query parameters', () async {
      // Arrange
      when(() => dio.get(
        '/analytics',
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/analytics'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      // Act
      await service.getAnalytics(storeId: 's1'); // Only storeId

      // Assert
      final captured = verify(() => dio.get(
        '/analytics',
        queryParameters: captureAny(named: 'queryParameters'),
      )).captured;
      final params = captured.first as Map<String, dynamic>;
      
      expect(params.keys.length, 1);
      expect(params['storeId'], 's1');
      expect(params.containsKey('areaId'), isFalse);
    });
  });
}
