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
    String? assignableAs,
    String? exceptUser,
    bool includeInactive = false,
    String? province,
    String? district,
    String? managerName,
  }) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (assignableAs != null) params['assignable_as'] = assignableAs;
    if (exceptUser != null) params['except_user'] = exceptUser;
    if (includeInactive) params['includeInactive'] = 'true';
    if (province != null && province.isNotEmpty) params['province'] = province;
    if (district != null && district.isNotEmpty) params['district'] = district;
    if (managerName != null && managerName.isNotEmpty) {
      params['managerName'] = managerName;
    }

    final response = await _dio.get(
      '/stores',
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );

    return IsolateParser.parseList<StoreDto>(
      json: response.data,
      parser: StoreDto.fromJson,
      listKey:
          'items', // IsolateParser gracefully falls back to flat list if data is not a Map
    );
  }

  /// POST /stores — create a new store.
  Future<Map<String, dynamic>> createStore({
    required String name,
    String? address,
    double? gpsLat,
    double? gpsLng,
    // SL-1: Structured address fields
    String? province,
    String? district,
    String? ward,
    String? street,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (address != null) body['address'] = address;
    if (gpsLat != null) body['gpsLat'] = gpsLat;
    if (gpsLng != null) body['gpsLng'] = gpsLng;
    if (province != null) body['province'] = province;
    if (district != null) body['district'] = district;
    if (ward != null) body['ward'] = ward;
    if (street != null) body['street'] = street;

    final response = await _dio.post('/stores', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /stores/{id} — update store metadata.
  Future<Map<String, dynamic>> updateStore(
    String id, {
    String? name,
    String? address,
    double? gpsLat,
    double? gpsLng,
    bool? isActive,
    // SL-1: Structured address fields
    String? province,
    String? district,
    String? ward,
    String? street,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (gpsLat != null) body['gpsLat'] = gpsLat;
    if (gpsLng != null) body['gpsLng'] = gpsLng;
    if (isActive != null) body['isActive'] = isActive;
    if (province != null) body['province'] = province;
    if (district != null) body['district'] = district;
    if (ward != null) body['ward'] = ward;
    if (street != null) body['street'] = street;

    final response = await _dio.put('/stores/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /stores/{id} — soft-delete (sets IsActive = false).
  Future<void> deleteStore(String id) async {
    await _dio.delete('/stores/$id');
  }

  /// GET /reference/locations — returns the 63 official Vietnam province names.
  /// SL-1: Used to populate the Province dropdown in [StoreFormSheet].
  Future<List<String>> fetchProvinces() async {
    final response = await _dio.get(
      '/reference/locations',
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data;
    if (data is List) return data.cast<String>();
    return [];
  }

  /// GET /reference/districts — returns list of distinct districts for a province.
  Future<List<String>> fetchDistricts(String province) async {
    final response = await _dio.get(
      '/reference/districts',
      queryParameters: {'province': province},
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data;
    if (data is List) return data.cast<String>();
    return [];
  }
}
