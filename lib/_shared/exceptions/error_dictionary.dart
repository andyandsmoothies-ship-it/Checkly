/// Maps normalized [AppError.code] values to empathetic, user-facing strings.
///
/// All strings follow the Checkly UX Copywriting rules:
///   - Blame-free: never say "you did something wrong"
///   - Verb-driven CTAs: "Try again", "Refresh", "Check your connection"
///   - No developer jargon: no HTTP codes, no exception names
///
/// [lookup] returns a generic fallback for unknown codes — it never returns null.
final class ErrorDictionary {
  ErrorDictionary._();

  static const String _fallback = 'Something went wrong. Please try again.';

  // ---------------------------------------------------------------------------
  // Connectivity errors
  // ---------------------------------------------------------------------------

  /// Displayed when a connection/send/receive timeout or no-internet error occurs.
  static const String _networkTimeout =
      "We couldn't connect. Check your connection and try again.";

  /// Displayed when the body cannot be parsed (e.g. HTML from NGINX).
  static const String _networkError =
      "We couldn't connect. Check your connection and try again.";

  // ---------------------------------------------------------------------------
  // Domain / HTTP-derived errors
  // ---------------------------------------------------------------------------

  static const String _validationError =
      "Some information looks incorrect. Please review and try again.";

  static const String _unauthorized =
      "Your session has expired. Please sign in again.";

  static const String _forbidden = "You don't have permission to do that.";

  static const String _notFound = "We couldn't find what you were looking for.";

  static const String _conflict =
      "This record was changed by someone else. Refresh and try again.";

  static const String _serverError =
      "Something went wrong on our end. Try again shortly.";

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a user-facing string for [code].
  /// Falls back to a generic message if [code] is not in the dictionary.
  static String lookup(String code) {
    return _map[code] ?? _fallback;
  }

  static const Map<String, String> _map = {
    'network_timeout': _networkTimeout,
    'network_error': _networkError,
    'validation_error': _validationError,
    'unauthorized': _unauthorized,
    'forbidden': _forbidden,
    'not_found': _notFound,
    'conflict': _conflict,
    'server_error': _serverError,
    'unknown': _fallback,
  };
}
