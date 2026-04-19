import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

/// Tiny stat chip with icon + label.
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const StatChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.displayStyle(
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
