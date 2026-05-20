import 'package:dio/dio.dart';
import '../model/user_session.dart';

/// API service for authentication endpoints.
/// Wraps Dio calls to POST /auth/login and POST /auth/register.
class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  /// POST /auth/login → UserSession
  Future<UserSession> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return UserSession.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/register → UserSession
  Future<UserSession> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? adminToken,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
      },
      options: adminToken != null
          ? Options(headers: {'Authorization': 'Bearer $adminToken'})
          : null,
    );
    return UserSession.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /sync/profile → profile snapshot with optional assigned store IDs.
  Future<Map<String, dynamic>> syncProfile() async {
    final response = await _dio.get('/sync/profile');
    return response.data as Map<String, dynamic>;
  }

  /// POST /users/me/device-tokens — registers the device's FCM token with the server.
  ///
  /// CRIT-02: This method was entirely missing. Without it, the backend stores table
  /// `user_device_tokens` is always empty and push notifications can never be delivered.
  /// Call this from the auth manager immediately after a successful login, passing the
  /// FCM token obtained from `firebase_messaging`.
  ///
  /// [platform] must be "android" or "ios".
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/users/me/device-tokens',
      data: {'token': token, 'platform': platform},
    );
  }
}
