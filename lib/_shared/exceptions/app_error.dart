import 'package:dio/dio.dart';

/// A typed, app-level error model derived from a raw [DioException].
///
/// This is a **data record**, not an Exception subtype.
/// Its only job is to carry a normalized error [code] and optional metadata
/// from the network layer to the UI layer.
///
/// Connectivity codes:
///   - `network_timeout` — connection/send/receive timeout, or no internet
///   - `network_error`  — any other DioException (e.g. HTML from NGINX, parse failure)
///
/// Domain codes mirror the RFC-9457 `code` extension field from the backend.
final class AppError {
  /// Normalized error code. Examples: `'conflict'`, `'network_timeout'`, `'unknown'`.
  final String code;

  /// Human-readable message (from the backend `detail` field, if available).
  /// May be empty — callers should prefer [ErrorDictionary.lookup] for display text.
  final String message;

  /// Raw detail string from the backend response, if present.
  final String? details;

  /// If true and [code] is a connectivity code, [ErrorDisplayService] will
  /// suppress the SnackBar. Used by offline-first managers that have already
  /// written data locally and do not want to alarm the user.
  final bool isOfflineExpected;

  const AppError({
    required this.code,
    this.message = '',
    this.details,
    this.isOfflineExpected = false,
  });

  /// Factory: converts a raw [DioException] into a typed [AppError].
  ///
  /// **Never throws.** All JSON parsing is wrapped in try/catch.
  /// Falls back to `code: 'network_error'` if the body cannot be parsed.
  factory AppError.fromDioException(DioException e) {
    // Connectivity/timeout errors have no HTTP response body.
    if (_isConnectivityError(e)) {
      return const AppError(code: 'network_timeout');
    }

    // Try to extract the RFC-9457 `code` field from the response body.
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] as String?;
        final detail = data['detail'] as String?;
        if (code != null && code.isNotEmpty) {
          return AppError(code: code, message: detail ?? '');
        }

        // Map HTTP status codes to known codes when `code` field is absent.
        final status = e.response?.statusCode;
        return AppError(code: _codeFromStatus(status), message: detail ?? '');
      }
    } catch (_) {
      // Body was not parseable JSON (e.g. HTML from NGINX).
    }

    return const AppError(code: 'network_error');
  }

  // ---------------------------------------------------------------------------

  static bool _isConnectivityError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  static String _codeFromStatus(int? status) {
    return switch (status) {
      400 => 'validation_error',
      401 => 'unauthorized',
      403 => 'forbidden',
      404 => 'not_found',
      409 => 'conflict',
      _ when status != null && status >= 500 => 'server_error',
      _ => 'unknown',
    };
  }
}
