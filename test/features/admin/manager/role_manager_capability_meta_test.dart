import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/admin/manager/role_manager.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';

class MockAdminApiService extends Mock implements AdminApiService {}

void main() {
  late RoleManager manager;
  late MockAdminApiService api;

  setUp(() {
    api = MockAdminApiService();
    manager = RoleManager(adminApiService: api);
  });

  group('RoleManager — PBAC Slice 2: Catalog Metadata', () {
    test('loadCatalog populates both catalog and catalogMeta from getCapabilityCatalogFull', () async {
      // Arrange
      final mockedCaps = ['templates:create'];
      final mockedMeta = {
        'templates:create': const CapabilityMeta(
          label: 'Create Templates',
          group: 'Templates',
          description: 'Desc',
        ),
      };

      when(() => api.getCapabilityCatalogFull())
          .thenAnswer((_) async => (mockedCaps, mockedMeta));

      // Initially null
      expect(manager.catalogMeta.value, isNull);

      // Act
      await manager.loadCatalog();

      // Assert
      expect(manager.catalog.value, equals(mockedCaps));
      expect(manager.catalogMeta.value, equals(mockedMeta));
      verify(() => api.getCapabilityCatalogFull()).called(1);
    });
  });
}
