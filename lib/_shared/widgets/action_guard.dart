import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/manager/auth_manager.dart';

/// Conditionally renders [child] based on entity-level action availability.
///
/// **Online path** (`actions` is non-null):
///   The server has returned a computed list of allowed actions for this entity.
///   The widget renders [child] only if [requiredAction] is in that list.
///   An empty list is treated as explicit deny — [fallbackCapability] is NOT checked.
///
/// **Offline path** (`actions` is null):
///   The entity was loaded from local Drift cache and has no server-computed list.
///   The widget falls back to checking the user's JWT-based capability set
///   via [fallbackCapability].
///
/// Example:
/// ```dart
/// ActionGuard(
///   actions: submission.allowedActions, // null when offline
///   requiredAction: SubmissionActions.finalize,
///   fallbackCapability: AppCapabilities.submissionsReview,
///   child: FinalizeButton(),
/// )
/// ```
class ActionGuard extends StatelessWidget {
  /// The list of allowed action keys returned from the server DTO.
  /// - Non-null → online path: server-computed, entity-state-aware.
  /// - Null → offline path: falls back to [fallbackCapability].
  final List<String>? actions;

  /// The action key to check (e.g., [SubmissionActions.finalize]).
  final String requiredAction;

  /// The global JWT capability to use when [actions] is null (offline).
  /// Must match a key from [AppCapabilities].
  final String fallbackCapability;

  /// The widget to render when the action is permitted.
  final Widget child;

  const ActionGuard({
    super.key,
    this.actions,
    required this.requiredAction,
    required this.fallbackCapability,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Online path: server has provided a definitive list.
    // An empty list is explicit deny — do not check fallback.
    if (actions != null) {
      return actions!.contains(requiredAction)
          ? child
          : const SizedBox.shrink();
    }

    // Offline path: no server list available.
    // Use ValueListenableBuilder to react to live capability changes.
    return ValueListenableBuilder<Set<String>>(
      valueListenable: GetIt.instance<AuthManager>().capabilities,
      builder: (context, caps, _) {
        return caps.contains(fallbackCapability)
            ? child
            : const SizedBox.shrink();
      },
    );
  }
}
