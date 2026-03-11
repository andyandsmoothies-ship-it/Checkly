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
}
