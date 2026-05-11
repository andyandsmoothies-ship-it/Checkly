import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/manager/auth_manager.dart';

final _di = GetIt.instance;

/// Conditionally renders [child] based on a PBAC capability check.
///
/// If the current user has [capability], [child] is rendered.
/// Otherwise, [fallback] is rendered (defaults to [SizedBox.shrink]).
///
/// Example:
/// ```dart
/// PermissionGuard(
///   capability: 'templates:create',
///   child: FloatingActionButton(onPressed: ..., child: Icon(Icons.add)),
/// )
/// ```
class PermissionGuard extends StatelessWidget {
  final String capability;
  final Widget child;
  final Widget? fallback;
  final bool showAsDisabled;
  final String? disabledTooltip;

  const PermissionGuard({
    super.key,
    required this.capability,
    required this.child,
    this.fallback,
    this.showAsDisabled = false,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _di<AuthManager>().capabilities,
      builder: (context, caps, _) {
        final allowed = caps.contains(capability);

        if (allowed) return child;

        if (showAsDisabled) {
          Widget disabledChild = IgnorePointer(
            child: Opacity(opacity: 0.5, child: child),
          );

          if (disabledTooltip != null) {
            disabledChild = Tooltip(
              message: disabledTooltip!,
              child: disabledChild,
            );
          }

          return disabledChild;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
