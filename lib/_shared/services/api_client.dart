import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Produces a compact, meaningful summary of an API response body.
/// - Map: shows keys, array lengths, and first-item preview
/// - List: shows count + first item
/// - Primitive: shows value directly
String _summarize(dynamic data) {
  if (data is Map<String, dynamic>) {
    final parts = <String>[];
    for (final entry in data.entries) {
      if (entry.value is List) {
        final list = entry.value as List;
        final firstItem = list.isNotEmpty
            ? _truncate(list.first.toString(), 120)
            : 'empty';
        parts.add('${entry.key}: List[${list.length}] → $firstItem');
      } else {
        parts.add('${entry.key}: ${_truncate(entry.value.toString(), 80)}');
      }
    }
    return '{${parts.join(', ')}}';
  }
  if (data is List) {
    final first = data.isNotEmpty
        ? _truncate(data.first.toString(), 120)
        : 'empty';
    return 'List[${data.length}] → $first';
  }
  return data?.toString() ?? 'null';
}

String _truncate(String s, int max) =>
    s.length > max ? '${s.substring(0, max)}…' : s;

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
          debugPrint('[API]    ${_summarize(response.data)}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint(
            '[API] ✖ ${error.response?.statusCode ?? "?"} '
            '${error.requestOptions.path}: ${error.message}',
          );
          if (error.response?.data != null) {
            debugPrint('[API]    ${_summarize(error.response!.data)}');
          }
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
