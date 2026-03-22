import 'package:flutter/material.dart';

/// A reusable guard that prevents accidental back-navigation when a form
/// has unsaved changes. Wraps its child in [PopScope] and shows a
/// confirmation dialog when [isDirty] is true and the user tries to pop.
///
/// Usage:
/// ```dart
/// UnsavedChangesGuard(
///   isDirty: _isDirty,
///   child: Scaffold(...),
/// )
/// ```
class UnsavedChangesGuard extends StatelessWidget {
  /// Whether the form has unsaved changes.
  final bool isDirty;

  /// The child widget (typically a Scaffold or sheet content).
  final Widget child;

  /// Optional custom dialog title. Defaults to 'Discard changes?'.
  final String? title;

  /// Optional custom dialog message.
  final String? message;

  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title ?? 'Discard changes?'),
            content: Text(
              message ?? 'You have unsaved changes that will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
