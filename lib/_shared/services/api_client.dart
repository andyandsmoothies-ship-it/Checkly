import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API base URL — configurable via `--dart-define=API_BASE_URL=...`.
/// Defaults to Android emulator localhost mapping for development.
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5288/api',
);

/// Creates a configured [Dio] instance with JSON defaults and logging.
Dio createDio({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Logging in debug mode only
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ),
    );
  }

  return dio;
}

/// Typed API client wrapping [Dio] for all backend calls.
/// Feature-specific API services receive this via DI.
class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  /// Sets the auth token for all subsequent requests.
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clears the auth token (logout).
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}
