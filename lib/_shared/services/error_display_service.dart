import 'package:flutter/material.dart';

import '../exceptions/app_error.dart';
import '../exceptions/error_dictionary.dart';

/// Singleton service for displaying empathetic error messages to the user.
///
/// **Usage:**
/// ```dart
/// di<ErrorDisplayService>().show(AppError.fromDioException(e));
/// di<ErrorDisplayService>().show(appError, onRetry: () => myManager.reload());
/// ```
///
/// **Guards:**
///   - If [navigatorKey.currentContext] is null (app not fully mounted), the
///     error is silently dropped with a debug print.
///   - If `isOfflineExpected` is true on the [AppError] and the code is a
///     connectivity error, the display is suppressed (data is safe locally).
///   - Duplicate error codes within an 800ms window are debounced to prevent
///     SnackBar spam from concurrent failures (e.g. a sync batch).
///
/// **NavigatorKey source:** Always use `appRouter.routerDelegate.navigatorKey`.
/// Do NOT create a separate GlobalKey — one NavigatorKey for the entire app.
class ErrorDisplayService {
  final GlobalKey<NavigatorState> _navigatorKey;

  /// Private debounce state: track last shown code + timestamp.
  String? _lastCode;
  DateTime? _lastShownAt;

  static const Duration _debounceWindow = Duration(milliseconds: 800);

  // Connectivity-type codes that qualify for the `isOfflineExpected` silent path.
  static const _connectivityCodes = {'network_timeout', 'network_error'};

  ErrorDisplayService(this._navigatorKey);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Shows an empathetic SnackBar for [error].
  ///
  /// Optional [onRetry]: if provided, a `[Retry]` action button appears.
  void show(AppError error, {VoidCallback? onRetry}) {
    // Guard 1: Offline-expected silent path
    if (error.isOfflineExpected && _connectivityCodes.contains(error.code)) {
      return;
    }

    // Guard 2: Debounce — same code shown within window
    final now = DateTime.now();
    if (_lastCode == error.code &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _debounceWindow) {
      return;
    }

    // Guard 3: NavigatorKey context must be available
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint(
        '[ErrorDisplayService] Warning: navigatorKey.currentContext is null. '
        'Dropping error display for code="${error.code}".',
      );
      return;
    }

    // Update debounce state BEFORE triggering UI (prevents re-entry)
    _lastCode = error.code;
    _lastShownAt = now;

    final message = ErrorDictionary.lookup(error.code);

    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      action: onRetry != null
          ? SnackBarAction(label: 'Retry', onPressed: onRetry)
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
