import '../constants/app_capabilities.dart';
import '../../features/auth/manager/auth_manager.dart';

/// Synchronous PBAC capability evaluator.
///
/// Wraps [AuthManager.capabilities] for capability-based access control.
/// All methods are SYNCHRONOUS — safe for use in GoRouter redirects.
///
/// NOTE: [PolicyManager] does NOT own capability state. It delegates to
/// [AuthManager.capabilities] which is the single source of truth.
///
/// PBAC Policy Transform (Option D):
/// [can] intercepts [AppCapabilities.adminAccess] and evaluates it
/// against [AppCapabilities.adminDomainCapabilities] via Set.intersection.
/// This means `admin:access` is granted implicitly if the user holds any
/// admin-domain capability, without backend or DB changes.
class PolicyManager {
  final AuthManager _auth;

  PolicyManager({required AuthManager auth}) : _auth = auth;

  /// Returns true if the current user's capability set satisfies [capability].
  ///
  /// For [AppCapabilities.adminAccess] specifically: returns true if the user
  /// holds [AppCapabilities.adminAccess] explicitly OR if their capabilities
  /// intersect [AppCapabilities.adminDomainCapabilities] (implicit grant).
  ///
  /// Returns false if capabilities have not yet been loaded (fail-safe deny).
  bool can(String capability) {
    final caps = _auth.capabilities.value;
    if (capability == AppCapabilities.adminAccess) {
      return caps.contains(AppCapabilities.adminAccess) ||
          caps.intersection(AppCapabilities.adminDomainCapabilities).isNotEmpty;
    }
    return caps.contains(capability);
  }

  /// Returns true if the user has at least one capability loaded.
  /// Can be used as a proxy for "is the PBAC cache warmed up".
  bool get isLoaded => _auth.capabilities.value.isNotEmpty;
}
