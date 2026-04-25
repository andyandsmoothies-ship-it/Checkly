import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

/// Small muted badge for scoring rules.
class RuleBadge extends StatelessWidget {
  final String label;
  const RuleBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppFonts.displayStyle(
          fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
