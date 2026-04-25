import 'package:dio/dio.dart';

/// Fetches the calling user's PBAC capability set from the backend.
///
/// API contract: `GET /api/system/capabilities`
/// Response shape: `{ "role": "admin", "capabilities": ["templates:create", ...] }`
///
/// The base URL already includes `/api` (configured in ApiClient / Dio setup),
/// so the path here is just `/system/capabilities`.
class PolicyApiService {
  final Dio _dio;

  PolicyApiService(this._dio);

  /// Returns the list of capability strings for the authenticated user's role.
  /// Throws [DioException] on network error or non-2xx response.
  Future<List<String>> fetchCapabilities() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/system/capabilities',
    );
    final data = response.data!;
    return List<String>.from(data['capabilities'] as List);
  }
}
