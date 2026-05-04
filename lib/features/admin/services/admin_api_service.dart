import 'package:dio/dio.dart';

import '../model/role_dto.dart';

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
    String? virtualAreaId,
    List<String>? assignedStoreIds,
    bool forceReassign = false,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null && fullName.isNotEmpty) body['fullName'] = fullName;
    if (role != null) body['role'] = role;
    if (storeId != null) body['storeId'] = storeId;
    if (areaId != null) body['areaId'] = areaId;
    if (virtualAreaId != null) body['virtualAreaId'] = virtualAreaId;
    if (assignedStoreIds != null) body['assignedStoreIds'] = assignedStoreIds;
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
    String? virtualAreaId,
    List<String>? assignedStoreIds,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
    };
    if (storeId != null) body['storeId'] = storeId;
    if (areaId != null) body['areaId'] = areaId;
    if (virtualAreaId != null) body['virtualAreaId'] = virtualAreaId;
    if (assignedStoreIds != null) body['assignedStoreIds'] = assignedStoreIds;

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

  // ── Role Capabilities API (PBAC Admin Slice 2) ──

  /// GET /admin/roles — list all roles with their assigned capabilities.
  Future<List<RoleDto>> getRoles() async {
    final response = await _dio.get('/admin/roles');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RoleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /admin/capabilities/catalog — returns the static capability catalog.
  /// NOTE: Server wraps response in CatalogResponse DTO: { "capabilities": [...] }.
  /// Do NOT cast response.data directly to List — it is a Map envelope.
  Future<List<String>> getCapabilityCatalog() async {
    final (caps, _) = await getCapabilityCatalogFull();
    return caps;
  }

  /// GET /admin/capabilities/catalog — returns both capabilities and metadata.
  Future<(List<String>, Map<String, CapabilityMeta>)>
  getCapabilityCatalogFull() async {
    final response = await _dio.get('/admin/capabilities/catalog');
    final data = response.data as Map<String, dynamic>;

    final list = data['capabilities'] as List<dynamic>;
    final caps = list.map((e) => e as String).toList();

    final metaRaw = data['capabilityMetadata'] as Map<String, dynamic>? ?? {};
    final meta = metaRaw.map(
      (k, v) => MapEntry(k, CapabilityMeta.fromJson(v as Map<String, dynamic>)),
    );

    return (caps, meta);
  }

  /// POST /admin/roles/{role}/capabilities/{capability} — idempotent grant.
  Future<void> grantCapability({
    required String role,
    required String capability,
  }) async {
    await _dio.post('/admin/roles/$role/capabilities/$capability');
  }

  /// DELETE /admin/roles/{role}/capabilities/{capability} — idempotent revoke.
  Future<void> revokeCapability({
    required String role,
    required String capability,
  }) async {
    await _dio.delete('/admin/roles/$role/capabilities/$capability');
  }

  // ── Global Risk API ──

  /// GET /global-risks — list all global risks (paginated, any authenticated user).
  /// NOTE: Backend returns a PagedResult[T] envelope: { "items": [...], "total": N }.
  /// Unwrap the 'items' key per Gotcha D.
  Future<List<Map<String, dynamic>>> getGlobalRisks() async {
    final allRisks = <Map<String, dynamic>>[];
    int page = 1;
    const pageSize = 100;

    while (true) {
      final response = await _dio.get(
        '/global-risks',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;
      allRisks.addAll(list.cast<Map<String, dynamic>>());

      if (list.length < pageSize) break;
      page++;
    }

    return allRisks;
  }

  /// POST /global-risks — create a new global risk (requires global_risks:manage).
  Future<Map<String, dynamic>> createGlobalRisk({
    required String label,
    String? description,
  }) async {
    final body = <String, dynamic>{'label': label};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _dio.post('/global-risks', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /global-risks/{id} — partial update (requires global_risks:manage).
  Future<Map<String, dynamic>> updateGlobalRisk(
    String id, {
    String? label,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (description != null) body['description'] = description;
    if (isActive != null) body['isActive'] = isActive;
    final response = await _dio.put('/global-risks/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /global-risks/{id} — soft-delete (sets isActive=false) via delete endpoint.
  Future<void> deleteGlobalRisk(String id) async {
    await _dio.delete('/global-risks/$id');
  }
}

class CapabilityMeta {
  final String label;
  final String group;
  final String description;

  const CapabilityMeta({
    required this.label,
    required this.group,
    required this.description,
  });

  factory CapabilityMeta.fromJson(Map<String, dynamic> json) {
    return CapabilityMeta(
      label: json['label'] as String,
      group: json['group'] as String,
      description: json['description'] as String,
    );
  }
}
