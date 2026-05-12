import 'package:flutter/material.dart';

/// A colored icon representing a program assignment's status.
///
/// Used in the [ProgramDashboardPage] assignment list tiles.
class ProgramStatusIcon extends StatelessWidget {
  final String status;

  const ProgramStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      'submitted' => Icon(Icons.check_circle, color: colorScheme.secondary),
      'verified' => Icon(Icons.verified, color: colorScheme.primary),
      'needs_revision' => Icon(Icons.error, color: colorScheme.error),
      'overdue' => Icon(Icons.warning_amber, color: colorScheme.tertiary),
      _ => Icon(
        Icons.pending_outlined,
        color: colorScheme.surfaceContainerHighest,
      ),
    };
  }
}
