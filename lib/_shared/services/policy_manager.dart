import '../../features/auth/manager/auth_manager.dart';

/// Synchronous PBAC capability evaluator.
///
/// Wraps [AuthManager.capabilities] for capability-based access control.
/// All methods are SYNCHRONOUS — safe for use in GoRouter redirects.
///
/// Capabilities are populated on login (Slice 4) and persist across
/// app restarts via the local [PolicyDao] Drift table.
///
/// NOTE: [PolicyManager] does NOT own capability state. It delegates to
/// [AuthManager.capabilities] which is the single source of truth.
class PolicyManager {
  final AuthManager _auth;

  PolicyManager({required AuthManager auth}) : _auth = auth;

  /// Returns true if the current user's capability set contains [capability].
  ///
  /// Returns false if capabilities have not yet been loaded (fail-safe deny).
  bool can(String capability) => _auth.capabilities.value.contains(capability);

  /// Returns true if the user has at least one capability loaded.
  /// Can be used as a proxy for "is the PBAC cache warmed up".
  bool get isLoaded => _auth.capabilities.value.isNotEmpty;
}
