import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../locator.dart';
import '../../features/auth/manager/auth_manager.dart';

/// API base URL — configurable via `--dart-define=API_BASE_URL=...`.
/// Defaults to Android emulator localhost mapping for development.
const String _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5288/api',
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

  // Global 401 interceptor for token expiration/revocation
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          if (!path.contains('/auth/login') && !path.contains('/auth/register')) {
            try {
              di<AuthManager>().logout();
            } catch (e) {
              debugPrint('[API] Failed to auto-logout on 401: $e');
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  // Compact logging in debug mode only — shows response shape, not raw dumps.
  // kDebugMode is compile-time false in release → entire block is tree-shaken out.
  if (kDebugMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[API] → ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.path}',
          );
          // debugPrint('[API]    ${_summarize(response.data)}'); // Disabled to reduce console spam
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint(
            '[API] ✖ ${error.response?.statusCode ?? "?"} '
            '${error.requestOptions.path}: ${error.message}',
          );
          // if (error.response?.data != null) {
          //   debugPrint('[API]    ${_summarize(error.response!.data)}');
          // }
          handler.next(error);
        },
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
