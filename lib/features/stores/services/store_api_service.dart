import 'package:dio/dio.dart';

import '../../../_shared/utils/isolate_parser.dart';
import '../model/store_dto.dart';

/// API service for store endpoints.
class StoreApiService {
  final Dio _dio;

  StoreApiService(this._dio);

  /// GET /stores — returns list of [StoreDto].
  /// [assignableAs] — 'store_manager' to get only unoccupied active stores.
  /// [exceptUser] — userId to exclude from "occupied" check (for edit forms).
  Future<List<StoreDto>> getStores({
    String? search,
    String? areaId,
    String? assignableAs,
    String? exceptUser,
    bool includeInactive = false,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (areaId != null) params['areaId'] = areaId;
    if (assignableAs != null) params['assignable_as'] = assignableAs;
    if (exceptUser != null) params['except_user'] = exceptUser;
    if (includeInactive) params['includeInactive'] = 'true';

    final response = await _dio.get(
      '/stores',
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );
    
    return IsolateParser.parseList<StoreDto>(
      json: response.data,
      parser: StoreDto.fromJson,
      listKey: 'items', // IsolateParser gracefully falls back to flat list if data is not a Map
    );
  }

  /// POST /stores — create a new store.
  Future<Map<String, dynamic>> createStore({
    required String name,
    String? address,
    String? areaId,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (address != null) body['address'] = address;
    if (areaId != null) body['areaId'] = areaId;
    if (gpsLat != null) body['gpsLat'] = gpsLat;
    if (gpsLng != null) body['gpsLng'] = gpsLng;

    final response = await _dio.post('/stores', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /stores/{id} — update store metadata.
  Future<Map<String, dynamic>> updateStore(
    String id, {
    String? name,
    String? address,
    String? areaId,
    double? gpsLat,
    double? gpsLng,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (areaId != null) body['areaId'] = areaId;
    if (gpsLat != null) body['gpsLat'] = gpsLat;
    if (gpsLng != null) body['gpsLng'] = gpsLng;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _dio.put('/stores/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /stores/{id} — soft-delete (sets IsActive = false).
  Future<void> deleteStore(String id) async {
    await _dio.delete('/stores/$id');
  }
}
