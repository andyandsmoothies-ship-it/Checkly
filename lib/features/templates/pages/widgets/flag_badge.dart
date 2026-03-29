import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

/// Small CCP/RISK pill badge.
class FlagBadge extends StatelessWidget {
  final String label;
  final Color color;
  const FlagBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppFonts.displayStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
