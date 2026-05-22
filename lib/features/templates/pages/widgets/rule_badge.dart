import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

/// Small muted badge for scoring rules.
class RuleBadge extends StatelessWidget {
  final String label;
  const RuleBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.seaSponge,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.turtle, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.macaw,
        ),
      ),
    );
  }
}
