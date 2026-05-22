import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/user_groups/manager/user_group_manager.dart';
import 'package:checkly/features/user_groups/model/user_group_dto.dart';
import 'package:checkly/features/user_groups/services/user_group_api_service.dart';

class MockUserGroupApiService extends Mock implements UserGroupApiService {}

void main() {
  late MockUserGroupApiService api;
  late UserGroupManager manager;

  setUp(() {
    api = MockUserGroupApiService();
    manager = UserGroupManager(api);
  });

  group('UserGroupManager Unit Tests', () {
    test('UG-MGR-INIT-01: Verify initial manager state', () {
      expect(manager.groups, isEmpty);
      expect(manager.isLoading, isFalse);
      expect(manager.error, isNull);
    });

    test('UG-MGR-LOAD-01: Load groups success flow', () async {
      // Arrange
      const mockGroups = [
        UserGroupDto(id: '1', name: 'Group 1', description: 'Desc 1'),
        UserGroupDto(id: '2', name: 'Group 2', description: 'Desc 2'),
      ];
      when(() => api.listGroups()).thenAnswer((_) async => mockGroups);

      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      // Act
      final loadFuture = manager.loadGroups();

      // Assert isLoading is true during call
      expect(manager.isLoading, isTrue);
      expect(manager.error, isNull);

      await loadFuture;

      expect(manager.isLoading, isFalse);
      expect(manager.groups, equals(mockGroups));
      expect(manager.error, isNull);
      // listeners notified twice (once on start loading, once on completion)
      expect(notifyCount, equals(2));
    });

    test('UG-MGR-LOAD-02: Load groups empty flow', () async {
      // Arrange
      when(() => api.listGroups()).thenAnswer((_) async => <UserGroupDto>[]);

      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      // Act
      await manager.loadGroups();

      // Assert
      expect(manager.isLoading, isFalse);
      expect(manager.groups, isEmpty);
      expect(manager.error, isNull);
      expect(notifyCount, equals(2));
    });

    test('UG-MGR-ERR-01: 403 HTTP error mapping', () async {
      // Arrange
      when(() => api.listGroups()).thenThrow(Exception('403 Forbidden'));

      // Act
      await manager.loadGroups();

      // Assert
      expect(manager.isLoading, isFalse);
      expect(manager.groups, isEmpty);
      expect(
        manager.error,
        equals('You do not have permission to manage user groups.'),
      );
    });

    test('UG-MGR-ERR-02: 401 HTTP error mapping', () async {
      // Arrange
      when(() => api.listGroups()).thenThrow(Exception('401 Unauthorized'));

      // Act
      await manager.loadGroups();

      // Assert
      expect(manager.isLoading, isFalse);
      expect(manager.groups, isEmpty);
      expect(
        manager.error,
        equals('Your session has expired. Please sign in again.'),
      );
    });

    test('UG-MGR-ERR-03: SocketException/network error mapping', () async {
      // Arrange
      when(
        () => api.listGroups(),
      ).thenThrow(Exception('SocketException: Connection failed'));

      // Act
      await manager.loadGroups();

      // Assert
      expect(manager.isLoading, isFalse);
      expect(manager.groups, isEmpty);
      expect(
        manager.error,
        equals('No internet connection. Please try again.'),
      );
    });

    test('UG-MGR-ERR-04: Standard generic error mapping', () async {
      // Arrange
      when(
        () => api.listGroups(),
      ).thenThrow(Exception('500 Internal Server Error'));

      // Act
      await manager.loadGroups();

      // Assert
      expect(manager.isLoading, isFalse);
      expect(manager.groups, isEmpty);
      expect(manager.error, equals('Something went wrong. Please try again.'));
    });

    test(
      'UG-MGR-CREATE-01: Create group success flow (prepends item)',
      () async {
        // Arrange
        const existingGroups = [
          UserGroupDto(id: '2', name: 'Group 2', description: 'Desc 2'),
        ];
        manager.groups = List.of(existingGroups);

        const newGroup = UserGroupDto(
          id: '1',
          name: 'Group 1',
          description: 'Desc 1',
        );
        when(
          () => api.createGroup('Group 1', 'Desc 1'),
        ).thenAnswer((_) async => newGroup);

        int notifyCount = 0;
        manager.addListener(() => notifyCount++);

        // Act
        final success = await manager.createGroup('Group 1', 'Desc 1');

        // Assert
        expect(success, isTrue);
        expect(manager.groups, equals([newGroup, ...existingGroups]));
        expect(manager.error, isNull);
        expect(notifyCount, equals(1));
      },
    );

    test('UG-MGR-CREATE-02: Create group failure flow', () async {
      // Arrange
      when(
        () => api.createGroup('Group 1', 'Desc 1'),
      ).thenThrow(Exception('403 Forbidden'));

      int notifyCount = 0;
      manager.addListener(() => notifyCount++);

      // Act
      final success = await manager.createGroup('Group 1', 'Desc 1');

      // Assert
      expect(success, isFalse);
      expect(
        manager.error,
        equals('You do not have permission to manage user groups.'),
      );
      expect(notifyCount, equals(1));
    });
  });
}
