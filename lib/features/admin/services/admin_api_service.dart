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
    String? fullName,
    String? role,
    String? storeId,
    String? areaId,
    bool forceReassign = false,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null && fullName.isNotEmpty) body['fullName'] = fullName;
    if (role != null) body['role'] = role;
    if (storeId != null) body['storeId'] = storeId;
    if (areaId != null) body['areaId'] = areaId;
    if (forceReassign) body['forceReassign'] = true;

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
      data: {'isBanned': ban},
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
  Future<Map<String, dynamic>> getSystemLogs({
    int page = 1,
    int pageSize = 50,
    String? level,
    String? search,
    String? startDate,
    String? endDate,
    String? traceId,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (level != null && level != 'all') params['level'] = level;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (traceId != null) params['traceId'] = traceId;

    final response = await _dio.get('/admin/logs', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  /// POST /admin/users — create a new user (admin only).
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? storeId,
    String? areaId,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    };
    if (storeId != null) body['storeId'] = storeId;
    if (areaId != null) body['areaId'] = areaId;

    final response = await _dio.post('/admin/users', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// POST /admin/users/{id}/reset-password — admin resets a user's password.
  Future<void> resetPassword(String userId, String newPassword) async {
    await _dio.post(
      '/admin/users/$userId/reset-password',
      data: {'newPassword': newPassword},
    );
  }

  // ── Area API ──

  /// GET /areas — list all areas.
  Future<List<Map<String, dynamic>>> getAreas() async {
    final response = await _dio.get('/areas');
    final data = response.data;
    final list = (data is List) ? data : (data['items'] as List<dynamic>);
    return list.cast<Map<String, dynamic>>();
  }

  /// POST /areas — create a new area (admin only).
  Future<Map<String, dynamic>> createArea({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    final response = await _dio.post('/areas', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /areas/{id} — update an area (admin only).
  Future<Map<String, dynamic>> updateArea(
    String id, {
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    final response = await _dio.put('/areas/$id', data: body);
    return response.data as Map<String, dynamic>;
  }
}
