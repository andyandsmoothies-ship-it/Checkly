/// Centralized role string constants.
///
/// These values are the raw strings sent by the backend in JWT `role` claims
/// and accepted by the user registration API. All UI code that compares,
/// switches on, or passes role strings MUST use these constants instead of
/// inline literals to prevent silent typo bugs.
///
/// Usage:
/// ```dart
/// import 'package:checkly/constants/app_roles.dart';
///
/// if (role == AppRoles.admin) { ... }
/// selectedRole = AppRoles.storeManager;
/// ```
abstract final class AppRoles {
  /// Backend role: `'admin'` — full access.
  static const String admin = 'admin';

  /// Backend role: `'auditor'` — read-only field agent.
  static const String auditor = 'auditor';

  /// Backend role: `'store_manager'` — manages a single assigned store.
  static const String storeManager = 'store_manager';

  /// Backend role: `'area_manager'` — manages multiple assigned stores.
  static const String areaManager = 'area_manager';
}
