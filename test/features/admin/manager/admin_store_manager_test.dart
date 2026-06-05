import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/manager/admin_store_manager.dart';
import 'package:checkly/features/stores/model/store_dto.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';

class MockStoreApiService extends Mock implements StoreApiService {}

void main() {
  late AdminStoreManager manager;
  late MockStoreApiService api;

  setUp(() {
    api = MockStoreApiService();
    manager = AdminStoreManager(storeApi: api);
  });

  group('AdminStoreManager Filters & State —', () {
    final mockStore = StoreDto(
      id: 's1',
      name: 'Store 1',
      managerName: 'Manager M',
      address: '123 Main St',
      gpsLat: null,
      gpsLng: null,
      createdAt: DateTime.now(),
    );

    test('initial state has null filters', () {
      expect(manager.selectedProvince, isNull);
      expect(manager.selectedManagerName, isNull);
    });

    test('load calls api with active filters', () async {
      when(() => api.getStores(
        includeInactive: true,
        search: any(named: 'search'),
        province: any(named: 'province'),
        managerName: any(named: 'managerName'),
      )).thenAnswer((_) async => [mockStore]);

      await manager.load();

      expect(manager.stores, equals([mockStore]));
      verify(() => api.getStores(
        includeInactive: true,
        search: null,
        province: null,
        managerName: null,
      )).called(1);
    });

    test('setProvince updates province and triggers load', () async {
      when(() => api.getStores(
        includeInactive: true,
        province: 'Hồ Chí Minh',
        managerName: null,
      )).thenAnswer((_) async => []);

      await manager.setProvince('Hồ Chí Minh');

      expect(manager.selectedProvince, equals('Hồ Chí Minh'));
      verify(() => api.getStores(
        includeInactive: true,
        province: 'Hồ Chí Minh',
        managerName: null,
      )).called(1);
    });

    test('setManagerName updates managerName and triggers load', () async {
      when(() => api.getStores(
        includeInactive: true,
        province: null,
        managerName: 'Andy',
      )).thenAnswer((_) async => []);

      await manager.setManagerName('Andy');

      expect(manager.selectedManagerName, equals('Andy'));
      verify(() => api.getStores(
        includeInactive: true,
        province: null,
        managerName: 'Andy',
      )).called(1);
    });

    test('clearFilters resets all filters and triggers load', () async {
      manager.selectedProvince = 'Hồ Chí Minh';
      manager.selectedManagerName = 'Andy';

      when(() => api.getStores(
        includeInactive: true,
        province: null,
        managerName: null,
      )).thenAnswer((_) async => []);

      await manager.clearFilters();

      expect(manager.selectedProvince, isNull);
      expect(manager.selectedManagerName, isNull);
      verify(() => api.getStores(
        includeInactive: true,
        province: null,
        managerName: null,
      )).called(1);
    });
  });
}
