import 'package:dio/dio.dart';

/// API service for admin endpoints (/api/admin/*).
class AdminApiService {
  final Dio _dio;

  AdminApiService(this._dio);

  /// GET /admin/users — list all users with profile+role (paginated).
  Future<List<Map<String, dynamic>>> getUsers({
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _dio.get('/admin/users', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /admin/users — returns raw paginated envelope { items, total, page, pageSize }.
  Future<Map<String, dynamic>> getUsersRaw({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/admin/users',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /admin/users/{id} — update user role, store, or area.
  Future<Map<String, dynamic>> updateUser(
    String id, {
    String? role,
    String? storeId,
    String? areaCode,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (storeId != null) body['storeId'] = storeId;
    if (areaCode != null) body['areaCode'] = areaCode;

    final response = await _dio.put('/admin/users/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// POST /admin/users/{id}/ban — ban/unban a user.
  Future<Map<String, dynamic>> banUser(
    String id, {
    required bool ban,
    int durationDays = 36500,
  }) async {
    final response = await _dio.post(
      '/admin/users/$id/ban',
      data: {'ban': ban, 'durationDays': durationDays},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /admin/stores/{storeId}/transfer — transfer SM.
  Future<Map<String, dynamic>> transferStoreManager(
    String storeId, {
    required String newManagerId,
  }) async {
    final response = await _dio.post(
      '/admin/stores/$storeId/transfer',
      data: {'newManagerId': newManagerId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /admin/logs — list system logs.
  Future<List<Map<String, dynamic>>> getSystemLogs({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/admin/logs',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final list = response.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
