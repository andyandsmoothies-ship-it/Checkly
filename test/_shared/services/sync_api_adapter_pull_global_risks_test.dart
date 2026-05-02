import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/_shared/services/service_adapters.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SyncApiAdapter adapter;

  setUp(() {
    mockDio = MockDio();
    adapter = SyncApiAdapter(mockDio);
  });

  group('SyncApiAdapter.pullGlobalRisks', () {
    test('pullGlobalRisks_includesSinceQueryParam_whenTimestampProvided', () async {
      final since = DateTime.utc(2026, 5, 2, 11, 30);

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/global-risks'),
          data: {
            'items': List.generate(10, (index) => {'id': index}),
          },
        ),
      );

      final result = await adapter.pullGlobalRisks(since);

      expect(result, hasLength(10));
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/global-risks',
          queryParameters: {
            'page': 1,
            'pageSize': 100,
            'since': since.toIso8601String(),
          },
        ),
      ).called(1);
    });

    test('pullGlobalRisks_stopsAtMaxPages_whenServerAlwaysReturnsFull', () async {
      // Arrange
      // Server bug: always returns 100 items regardless of page
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/global-risks'),
          data: {
            'items': List.generate(100, (index) => {'id': index}),
          },
        );
      });

      // Act
      // We wrap in a timeout to ensure it doesn't hang forever if the fix isn't there,
      // throwing a specific exception so we know it's the expected RED failure.
      final result = await adapter
          .pullGlobalRisks(null)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () =>
                throw Exception('Infinite loop detected (Test Timeout)'),
          );

      // Assert
      // Max pages is 10, page size is 100, so max items is 1000.
      expect(result.length, 1000);
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(10);
    });

    test('pullGlobalRisks_stopsEarly_whenServerReturnsPartialPage', () async {
      // Arrange
      // Server returns 50 items (less than page size 100)
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/global-risks'),
          data: {
            'items': List.generate(50, (index) => {'id': index}),
          },
        ),
      );

      // Act
      final result = await adapter.pullGlobalRisks(null);

      // Assert
      expect(result.length, 50);
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
