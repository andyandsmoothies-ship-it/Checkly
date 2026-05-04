import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/stores/model/store_dto.dart';

/// DAO for cached store data.
class StoreDao {
  final AppDatabase _db;

  StoreDao(this._db);

  /// Read all cached stores.
  Future<List<StoreDto>> getAllStores() async {
    final profileRow = await (_db.select(_db.cachedProfiles)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    final isAreaManager = profileRow?.role == 'area_manager';
    final overrideIds = _parseAssignedStoreOverrides(
      profileRow?.assignedStoreOverrides,
    );

    final query = _db.select(_db.cachedStores)
      ..where((s) => s.isActive.equals(true))
      ..limit(1000); // Bounded to 1000 for memory safety (Gotcha #14)

    if (isAreaManager && overrideIds.isNotEmpty) {
      query.where((s) => s.id.isIn(overrideIds));
    } else if (isAreaManager && overrideIds.isEmpty) {
      query.where((_) => const Constant(false));
    }

    final rows = await query.get();
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

    areaId: row.areaId,
    areaName: row.areaName,
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

        areaId: Value(dto.areaId),
        areaName: Value(dto.areaName),
        gpsLat: Value(dto.gpsLat),
        gpsLng: Value(dto.gpsLng),
        isActive: Value(dto.isActive ?? true),
        createdAt: dto.createdAt,
        updatedAt: DateTime.now(),
      );

  List<String> _parseAssignedStoreOverrides(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
}
