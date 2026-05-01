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

  group('SyncApiAdapter.pullProgramAssignments', () {
    test('FE-GMA-BOUND-01: PullProgramAssignments_WhenBackendReturnsMultiplePages_AggregatesAllItemsIntoSingleList', () async {
      // Arrange
      // Page 1: 50 items, total 120
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 1, 'pageSize': 50},
        ),
      ).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/programs/assignments/my'),
            data: {
              'items': List.generate(50, (index) => {'id': index}),
              'total': 120,
              'page': 1,
              'pageSize': 50,
            },
          ));

      // Page 2: 50 items, total 120
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 2, 'pageSize': 50},
        ),
      ).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/programs/assignments/my'),
            data: {
              'items': List.generate(50, (index) => {'id': 50 + index}),
              'total': 120,
              'page': 2,
              'pageSize': 50,
            },
          ));

      // Page 3: 20 items, total 120
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 3, 'pageSize': 50},
        ),
      ).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/programs/assignments/my'),
            data: {
              'items': List.generate(20, (index) => {'id': 100 + index}),
              'total': 120,
              'page': 3,
              'pageSize': 50,
            },
          ));

      // Act
      final result = await adapter.pullProgramAssignments();

      // Assert
      expect(result.length, 120);
      
      // Verify exactly 3 API calls were made (currently failing because adapter only makes 1 GET without params)
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(3);
    });

    test('FE-GMA-BOUND-02: PullProgramAssignments_WhenLaterPageFails_RethrowsAndDoesNotInventPartialSuccess', () async {
      // Arrange
      // Page 1 succeeds
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 1, 'pageSize': 50},
        ),
      ).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/programs/assignments/my'),
            data: {
              'items': List.generate(50, (index) => {'id': index}),
              'total': 120,
              'page': 1,
              'pageSize': 50,
            },
          ));

      // Page 2 fails
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 2, 'pageSize': 50},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/programs/assignments/my'),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
        ),
      );

      // Act & Assert
      expect(
        () => adapter.pullProgramAssignments(),
        throwsA(isA<DioException>()),
      );
    });

    test('FE-GMA-EMPTY: PullProgramAssignments_WhenBackendReturnsEmpty_ReturnsEmptyList', () async {
      // Arrange
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: {'page': 1, 'pageSize': 50},
        ),
      ).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/programs/assignments/my'),
            data: {
              'items': [],
              'total': 0,
              'page': 1,
              'pageSize': 50,
            },
          ));

      // Act
      final result = await adapter.pullProgramAssignments();

      // Assert
      expect(result, isEmpty);
      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/programs/assignments/my',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
