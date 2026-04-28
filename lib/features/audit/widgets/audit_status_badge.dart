import 'package:flutter/material.dart';

/// Small colored badge for status indicators on the compact row.
class AuditStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AuditStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
