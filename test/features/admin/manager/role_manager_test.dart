import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:checkly/features/admin/manager/role_manager.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/features/admin/model/role_dto.dart';

class MockAdminApiService extends Mock implements AdminApiService {}
class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {}

void main() {
  group('Admin Dashboard UI — Role Management Inner-Loop (TDD)', () {
    
    // ==========================================
    // RoleDto Tests (TC-05)
    // ==========================================
    group('RoleDto (TC-05)', () {
      test('fromJson parses correctly', () {
        final json = {
          'role': 'admin',
          'capabilities': ['templates:create', 'templates:delete']
        };
        final dto = RoleDto.fromJson(json);
        expect(dto.role, 'admin');
        expect(dto.capabilities.length, 2);
        expect(dto.capabilities, contains('templates:create'));
      });
    });

    // ==========================================
    // AdminApiService Tests (TC-06, TC-07, TC-08)
    // ==========================================
    group('AdminApiService', () {
      late MockDio mockDio;
      late AdminApiService service;

      setUp(() {
        mockDio = MockDio();
        service = AdminApiService(mockDio);
      });

      test('TC-06: getRoles parses list of RoleDtos', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.data).thenReturn([
          {
            'role': 'admin',
            'capabilities': ['templates:create']
          }
        ]);
        
        when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => mockResponse);

        final roles = await service.getRoles();
        
        expect(roles.length, 1);
        expect(roles.first.role, 'admin');
        expect(roles.first.capabilities, contains('templates:create'));
        
        verify(() => mockDio.get('/admin/roles')).called(1);
      });

      test('TC-07: grantCapability posts correct endpoint', () async {
        when(() => mockDio.post(any(), data: any(named: 'data')))
            .thenAnswer((_) async => MockResponse());

        await service.grantCapability(role: 'auditor', capability: 'templates:create');
        
        verify(() => mockDio.post('/admin/roles/auditor/capabilities/templates:create')).called(1);
      });

      test('TC-08: revokeCapability deletes correct endpoint', () async {
        when(() => mockDio.delete(any(), data: any(named: 'data')))
            .thenAnswer((_) async => MockResponse());

        await service.revokeCapability(role: 'auditor', capability: 'templates:create');
        
        verify(() => mockDio.delete('/admin/roles/auditor/capabilities/templates:create')).called(1);
      });
    });

    // ==========================================
    // RoleManager Tests (TC-01 to TC-04)
    // ==========================================
    group('RoleManager', () {
      late MockAdminApiService mockService;
      late RoleManager manager;

      setUp(() {
        mockService = MockAdminApiService();
        // Assume manager takes service in constructor to allow DI/mocking, or GetIt handles it.
        manager = RoleManager(adminApiService: mockService);
      });

      test('TC-01: loadRoles sets isLoading then populates roles', () async {
        final mockRoles = [RoleDto(role: 'admin', capabilities: ['templates:create'])];
        when(() => mockService.getRoles()).thenAnswer((_) async => mockRoles);

        expect(manager.isLoading.value, false);
        expect(manager.roles.value, null);

        final future = manager.loadRoles();
        
        // Mid-flight state
        expect(manager.isLoading.value, true);
        
        await future;
        
        // Exit state
        expect(manager.isLoading.value, false);
        expect(manager.roles.value, isNotNull);
        expect(manager.roles.value!.length, 1);
        expect(manager.roles.value!.first.role, 'admin');
      });

      test('TC-02: loadRoles onError sets error string', () async {
        when(() => mockService.getRoles()).thenThrow(Exception('500 Server Error'));

        expect(manager.error.value, null);

        await manager.loadRoles();

        expect(manager.error.value, isNotNull);
        expect(manager.error.value, contains('500 Server Error'));
        expect(manager.isLoading.value, false);
        expect(manager.roles.value, null);
      });

      test('TC-03: grantCommand calls service and reloads', () async {
        // Arrange
        manager.roles.value = [RoleDto(role: 'auditor', capabilities: [])];
        
        when(() => mockService.grantCapability(role: any(named: 'role'), capability: any(named: 'capability')))
            .thenAnswer((_) async {});
            
        when(() => mockService.getRoles())
            .thenAnswer((_) async => [RoleDto(role: 'auditor', capabilities: ['templates:create'])]);

        // Act
        await manager.grantCommand.execute({'role': 'auditor', 'capability': 'templates:create'});

        // Assert
        verify(() => mockService.grantCapability(role: 'auditor', capability: 'templates:create')).called(1);
        verify(() => mockService.getRoles()).called(greaterThanOrEqualTo(1));
        
        expect(manager.roles.value!.first.capabilities, contains('templates:create'));
      });

      test('TC-04: revokeCommand calls service and reloads', () async {
        // Arrange
        manager.roles.value = [RoleDto(role: 'auditor', capabilities: ['templates:create'])];
        
        when(() => mockService.revokeCapability(role: any(named: 'role'), capability: any(named: 'capability')))
            .thenAnswer((_) async {});
            
        when(() => mockService.getRoles())
            .thenAnswer((_) async => [RoleDto(role: 'auditor', capabilities: [])]);

        // Act
        await manager.revokeCommand.execute({'role': 'auditor', 'capability': 'templates:create'});

        // Assert
        verify(() => mockService.revokeCapability(role: 'auditor', capability: 'templates:create')).called(1);
        verify(() => mockService.getRoles()).called(greaterThanOrEqualTo(1));
        
        expect(manager.roles.value!.first.capabilities, isEmpty);
      });
    });
  });
}
