import 'package:flutter/material.dart';

/// Reusable circular FAB with uppercase label below.
/// Matches the Apothecary "Floating Action Stack" pattern:
///   [Circle FAB with icon]
///   [Uppercase label below]
class ChecklyFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const ChecklyFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: const CircleBorder(),
            elevation: 8,
            child: Icon(icon, size: 32),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
