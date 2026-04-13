import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/admin/manager/role_manager.dart';
import 'package:checkly/features/admin/model/role_dto.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';

class MockAdminApiService extends Mock implements AdminApiService {}

void main() {
  late RoleManager manager;
  late MockAdminApiService api;

  setUp(() {
    api = MockAdminApiService();
    manager = RoleManager(adminApiService: api);
  });

  group('RoleManager State & Commands —', () {
    final mockRole = RoleDto(
      role: 'testing_role',
      capabilities: ['view_audit'],
    );
    final mockCatalog = ['view_audit', 'edit_audit'];

    test('loadRoles updates roles on success', () async {
      when(() => api.getRoles()).thenAnswer((_) async => [mockRole]);

      // Initially null
      expect(manager.roles.value, isNull);
      
      // Loading flag should trigger
      final loadingStates = <bool>[];
      manager.isLoading.addListener(() {
        loadingStates.add(manager.isLoading.value);
      });

      await manager.loadRoles();

      expect(manager.roles.value, equals([mockRole]));
      expect(manager.error.value, isNull);
      expect(loadingStates, containsAllInOrder([true, false]));
    });

    test('loadRoles sets error and clears roles on failure', () async {
      when(() => api.getRoles()).thenThrow(Exception('Server crash'));

      await manager.loadRoles();

      expect(manager.roles.value, isNull);
      expect(manager.error.value, contains('Server crash'));
    });

    test('loadCatalog updates catalog quietly', () async {
      when(() => api.getCapabilityCatalog()).thenAnswer((_) async => mockCatalog);

      await manager.loadCatalog();

      expect(manager.catalog.value, equals(mockCatalog));
    });

    test('grantCommand executes grant and reloads roles', () async {
      when(() => api.grantCapability(role: any(named: 'role'), capability: any(named: 'capability')))
          .thenAnswer((_) async {});
      when(() => api.getRoles()).thenAnswer((_) async => [mockRole]); // reload mock

      await manager.grantCommand.execute({'role': 'r1', 'capability': 'c1'});

      verify(() => api.grantCapability(role: 'r1', capability: 'c1')).called(1);
      verify(() => api.getRoles()).called(1);
    });

    test('revokeCommand executes revoke and reloads roles', () async {
      when(() => api.revokeCapability(role: any(named: 'role'), capability: any(named: 'capability')))
          .thenAnswer((_) async {});
      when(() => api.getRoles()).thenAnswer((_) async => []); // reload mock

      await manager.revokeCommand.execute({'role': 'r1', 'capability': 'c1'});

      verify(() => api.revokeCapability(role: 'r1', capability: 'c1')).called(1);
      verify(() => api.getRoles()).called(1);
    });
  });
}
