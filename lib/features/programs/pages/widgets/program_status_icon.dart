import 'package:flutter/material.dart';

/// A colored icon representing a program assignment's status.
///
/// Used in the [ProgramDashboardPage] assignment list tiles.
class ProgramStatusIcon extends StatelessWidget {
  final String status;

  const ProgramStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      'submitted' => const Icon(Icons.check_circle, color: Colors.blue),
      'verified' => const Icon(Icons.verified, color: Colors.green),
      'needs_revision' => const Icon(Icons.error, color: Colors.red),
      'overdue' => const Icon(Icons.warning_amber, color: Colors.orange),
      _ => const Icon(Icons.pending_outlined, color: Colors.grey),
    };
  }
}
