import 'package:dio/dio.dart';

import '../model/user_group_dto.dart';

/// HTTP service for the UserGroups API.
/// Endpoints: GET /api/user-groups, POST /api/user-groups
///
/// PFA Layer: Service — performs raw HTTP calls only, no state management.
class UserGroupApiService {
  final Dio _dio;

  UserGroupApiService(this._dio);

  /// Fetches all user groups (admin-only).
  /// Backend returns paginated { items: [...], total: N } shape.
  Future<List<UserGroupDto>> listGroups() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/user-groups');
    final data = res.data!;
    // Backend returns { items: [...] } paginated OR a plain list depending on version.
    // Handle both shapes defensively.
    final raw = data['items'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(UserGroupDto.fromJson)
        .toList();
  }

  /// Creates a new user group.
  /// Returns the newly created [UserGroupDto].
  Future<UserGroupDto> createGroup(String name, String? description) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/user-groups',
      data: {'name': name, 'description': description},
    );
    return UserGroupDto.fromJson(res.data!);
  }
}
