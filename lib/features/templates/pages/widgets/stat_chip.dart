import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

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
        Icon(icon, size: 14, color: AppColors.wolf),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.wolf,
          ),
        ),
      ],
    );
  }
}
