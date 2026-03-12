import 'package:dio/dio.dart';

import '../model/store_dto.dart';

/// API service for store endpoints.
class StoreApiService {
  final Dio _dio;

  StoreApiService(this._dio);

  /// GET /stores — returns list of [StoreDto] (with optional search).
  Future<List<StoreDto>> getStores({String? search}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get('/stores', queryParameters: params);
    final list = response.data as List<dynamic>;
    return list
        .map((j) => StoreDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// POST /stores — create a new store.
  Future<Map<String, dynamic>> createStore({
    required String name,
    String? address,
    String? areaCode,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (address != null) body['address'] = address;
    if (areaCode != null) body['areaCode'] = areaCode;
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
    String? areaCode,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (areaCode != null) body['areaCode'] = areaCode;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _dio.put('/stores/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /stores/{id} — soft-delete (sets IsActive = false).
  Future<void> deleteStore(String id) async {
    await _dio.delete('/stores/$id');
  }
}
