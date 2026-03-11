import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/stores/model/store_dto.dart';

/// DAO for cached store data.
class StoreDao {
  final AppDatabase _db;

  StoreDao(this._db);

  /// Read all cached stores.
  Future<List<StoreDto>> getAllStores() async {
    final rows = await _db.select(_db.cachedStores).get();
    return rows.map(_rowToDto).toList();
  }

  /// Upsert a batch of stores (full replace).
  Future<void> upsertStores(List<StoreDto> stores) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.cachedStores,
        stores.map(_dtoToCompanion).toList(),
      );
    });
  }

  // ---------- Mappers ----------

  StoreDto _rowToDto(CachedStore row) => StoreDto(
    id: row.id,
    name: row.name,
    address: row.address,
    areaCode: row.areaCode,
    gpsLat: row.gpsLat,
    gpsLng: row.gpsLng,
    isActive: row.isActive,
    createdAt: row.createdAt,
  );

  CachedStoresCompanion _dtoToCompanion(StoreDto dto) =>
      CachedStoresCompanion.insert(
        id: dto.id,
        name: dto.name,
        address: Value(dto.address),
        areaCode: Value(dto.areaCode),
        gpsLat: Value(dto.gpsLat),
        gpsLng: Value(dto.gpsLng),
        isActive: Value(dto.isActive ?? true),
        createdAt: dto.createdAt,
        updatedAt: DateTime.now(),
      );
}
