import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/user_groups/services/user_group_api_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late UserGroupApiService service;

  setUp(() {
    dio = MockDio();
    service = UserGroupApiService(dio);
  });

  group('UserGroupApiService Pathing Tests', () {
    test(
      'listGroups should call /user-groups (NOT /api/user-groups)',
      () async {
        // Arrange
        // Stub with dynamic generic — backend returns a raw JSON array
        when(() => dio.get<dynamic>('/user-groups')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/user-groups'),
            data: <dynamic>[],
            statusCode: 200,
          ),
        );

        // Act
        await service.listGroups();

        // Assert
        verify(() => dio.get<dynamic>('/user-groups')).called(1);
      },
    );

    test('createGroup should call /user-groups (NOT /api/user-groups)', () async {
      // Arrange
      const name = 'Admin Group';
      const desc = 'Description';

      when(
        () => dio.post<Map<String, dynamic>>(
          '/user-groups',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/user-groups'),
          data: {'id': '1', 'name': name, 'description': desc},
          statusCode: 201,
        ),
      );

      // Act
      await service.createGroup(name, desc);

      // Assert
      // This will fail (RED) because the existing implementation calls '/api/user-groups'
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/user-groups',
          data: {'name': name, 'description': desc},
        ),
      ).called(1);
    });
  });
}
