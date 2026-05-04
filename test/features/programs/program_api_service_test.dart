import 'package:checkly/_shared/constants/app_capabilities.dart';
import 'package:checkly/features/programs/services/program_api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProgramApiService service;

  setUp(() {
    mockDio = MockDio();
    service = ProgramApiService(mockDio);
  });

  group('ProgramApiService.createProgram', () {
    test('TC-01: createProgram posts correct payload', () async {
      // Arrange
      final deadline = DateTime.utc(2026, 6, 30, 23, 59, 59);
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/programs'),
          statusCode: 201,
          data: {
            'programId': '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
            'assignmentCount': 2,
          },
        ),
      );

      // Act
      final result = await service.createProgram(
        title: 'Q2 Hygiene Blitz',
        category: 'Hygiene',
        deadline: deadline,
        templateId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        storeIds: ['a1b2c3d4-1111', 'e5f6a7b8-2222'],
      );

      // Assert
      expect(result['programId'], '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d');
      expect(result['assignmentCount'], 2);

      verify(() => mockDio.post<Map<String, dynamic>>(
            '/programs',
            data: {
              'title': 'Q2 Hygiene Blitz',
              'category': 'Hygiene',
              'deadline': deadline.toIso8601String(),
              'templateId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
              'storeIds': ['a1b2c3d4-1111', 'e5f6a7b8-2222'],
            },
          )).called(1);
    });

    test('TC-02: createProgram throws on non-2xx', () async {
      // Arrange
      final deadline = DateTime.utc(2026, 6, 30, 23, 59, 59);
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/programs'),
        response: Response(
          requestOptions: RequestOptions(path: '/programs'),
          statusCode: 400,
          data: 'Bad Request',
        ),
      ));

      // Act & Assert
      expect(
        () => service.createProgram(
          title: 'Q2 Hygiene Blitz',
          category: 'Hygiene',
          deadline: deadline,
          templateId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
          storeIds: ['a1b2c3d4-1111', 'e5f6a7b8-2222'],
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AppCapabilities', () {
    test('TC-03: programsCreate constant exists', () {
      expect(AppCapabilities.programsCreate, 'programs:create');
    });
  });
}
