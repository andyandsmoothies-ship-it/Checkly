import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/stores/manager/store_manager.dart';
import 'package:checkly/features/stores/model/store_dto.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/_shared/database/dao/store_dao.dart';

class MockStoreApiService extends Mock implements StoreApiService {}

class MockStoreDao extends Mock implements StoreDao {}

void main() {
  late StoreManager manager;
  late MockStoreApiService api;
  late MockStoreDao dao;

  final storeZ = StoreDto(
    id: 's1',
    name: 'Zeta Store',
    areaId: 'a1',
    areaName: 'A',
    managerName: 'M',
    address: '1',
    createdAt: DateTime.now(),
  );
  final storeA = StoreDto(
    id: 's2',
    name: 'Alpha Store',
    areaId: 'a1',
    areaName: 'A',
    managerName: 'M',
    address: '1',
    createdAt: DateTime.now(),
  );
  final storeM = StoreDto(
    id: 's3',
    name: 'Mega Store',
    areaId: 'a1',
    areaName: 'A',
    managerName: 'M',
    address: '1',
    createdAt: DateTime.now(),
  );

  setUp(() {
    api = MockStoreApiService();
    dao = MockStoreDao();
    manager = StoreManager(api: api, dao: dao);
    registerFallbackValue([storeZ]);
  });

  group('StoreManager - Offline Search & Sort (TDD Slice 1) -', () {
    test('T3: loadStores() -> result is sorted alphabetically A->Z', () async {
      // Arrange
      // DAO returns unsorted: Z, A, M
      when(
        () => dao.getAllStores(),
      ).thenAnswer((_) async => [storeZ, storeA, storeM]);
      // API fails (offline)
      when(() => api.getStores()).thenThrow(Exception('Offline'));

      // Act
      await manager.loadStores();

      // Assert: List should be A, M, Z
      expect(manager.stores.value.map((s) => s.name).toList(), [
        'Alpha Store',
        'Mega Store',
        'Zeta Store',
      ]);
    });

    test(
      'T1: searchStores("mega") while offline -> stores list filters from cache in-memory',
      () async {
        // Arrange: Load stores first so cache is populated
        when(
          () => dao.getAllStores(),
        ).thenAnswer((_) async => [storeZ, storeA, storeM]);
        when(() => api.getStores()).thenThrow(Exception('Offline'));
        await manager.loadStores();

        // Clear interactions from loadStores so verifyNever is accurate
        clearInteractions(api);
        clearInteractions(dao);

        // Ensure API search throws if called
        when(
          () => api.getStores(search: any(named: 'search')),
        ).thenThrow(Exception('Offline Search Failed'));

        // Act
        await manager.searchStores('mega');

        // Assert: Only Mega Store is found
        expect(manager.stores.value.map((s) => s.name).toList(), [
          'Mega Store',
        ]);
        // Should NOT call API for search
        verifyNever(() => api.getStores(search: any(named: 'search')));
      },
    );

    test(
      'T2: searchStores("") -> restores full store list without API/DAO call',
      () async {
        // Arrange: Load stores first
        when(
          () => dao.getAllStores(),
        ).thenAnswer((_) async => [storeZ, storeA, storeM]);
        when(() => api.getStores()).thenThrow(Exception('Offline'));
        await manager.loadStores();

        // Clear interactions from loadStores
        clearInteractions(api);
        clearInteractions(dao);

        // Act 1: Search something to filter it
        when(
          () => api.getStores(search: any(named: 'search')),
        ).thenThrow(Exception('Offline Search Failed'));
        await manager.searchStores('alpha');

        // Act 2: Empty search
        await manager.searchStores('');

        // Assert: Full list restored (sorted)
        expect(manager.stores.value.map((s) => s.name).toList(), [
          'Alpha Store',
          'Mega Store',
          'Zeta Store',
        ]);
        // Should NOT call DAO again for the empty search
        verifyNever(() => dao.getAllStores());
        verifyNever(() => api.getStores(search: any(named: 'search')));
      },
    );
  });
}
