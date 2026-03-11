import 'package:dio/dio.dart';

import '../model/store_dto.dart';

/// API service for store endpoints.
class StoreApiService {
  final Dio _dio;

  StoreApiService(this._dio);

  /// GET /stores — returns list of [StoreDto].
  Future<List<StoreDto>> getStores() async {
    final response = await _dio.get('/stores');
    final list = response.data as List<dynamic>;
    return list
        .map((j) => StoreDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
