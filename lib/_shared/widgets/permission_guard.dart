import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/policy_manager.dart';

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

  const PermissionGuard({
    super.key,
    required this.capability,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = _di<PolicyManager>().can(capability);
    return allowed ? child : (fallback ?? const SizedBox.shrink());
  }
}
