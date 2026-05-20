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
  /// Backend currently returns a raw JSON array `[{...}]`.
  /// Handles both raw list and paginated envelope (`{items:[]}`) defensively.
  Future<List<UserGroupDto>> listGroups() async {
    final res = await _dio.get<dynamic>('/user-groups');
    final data = res.data;

    // Handle both raw list (current backend) and object envelope (legacy/future backend)
    List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      raw =
          data['items'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          [];
    } else {
      raw = [];
    }

    return raw.cast<Map<String, dynamic>>().map(UserGroupDto.fromJson).toList();
  }

  /// Creates a new user group.
  /// Returns the newly created [UserGroupDto].
  Future<UserGroupDto> createGroup(String name, String? description) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/user-groups',
      data: {'name': name, 'description': description},
    );
    return UserGroupDto.fromJson(res.data!);
  }

  /// PUT /user-groups/{id}/members — replaces the full member list of a group.
  ///
  /// CRIT-03: This method was entirely missing. The write path for group member management
  /// was a dead end — changes made in the UI could not be persisted to the server.
  /// Sends a full replacement list of profile IDs; the backend reconciles adds/removes.
  Future<void> updateGroupMembers(String groupId, List<String> profileIds) async {
    await _dio.put(
      '/user-groups/$groupId/members',
      data: {'profileIds': profileIds},
    );
  }
}
