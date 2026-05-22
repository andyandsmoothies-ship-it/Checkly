import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

/// Hero banner card — draws attention to a primary action.
///
/// Refactored to wrap inside StrokeCard for 2px Swan border, zero elevation,
/// and uses brand display fonts.
class HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const HeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ic = iconColor ?? theme.colorScheme.primary;

    return StrokeCard(
      onTap: onTap,
      color: color,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ic.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ic, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.displayStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.eel,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.displayStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.wolf,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.hare),
        ],
      ),
    );
  }
}
