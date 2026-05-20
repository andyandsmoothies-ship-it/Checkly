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

  setUp(() {
    api = MockStoreApiService();
    dao = MockStoreDao();

    manager = StoreManager(api: api, dao: dao);
  });

  group('StoreManager —', () {
    final mockStore = StoreDto(
      id: 's1',
      name: 'Store 1',
      managerName: 'Manager M',
      address: '123 Main St',
      gpsLat: null,
      gpsLng: null,
      createdAt: DateTime.now(),
    );

    test('loadStores fetches from cache and then updates from API', () async {
      when(() => dao.getAllStores()).thenAnswer((_) async => [mockStore]);
      when(() => api.getStores()).thenAnswer((_) async => [mockStore]);
      when(() => dao.upsertStores(any())).thenAnswer((_) async {});

      await manager.loadStores();

      expect(manager.stores.value, equals([mockStore]));
      verify(() => dao.getAllStores()).called(1);
      verify(() => api.getStores()).called(1);
      verify(() => dao.upsertStores([mockStore])).called(1);
    });
  });
}
