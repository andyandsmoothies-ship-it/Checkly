import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

/// A visually prominent featured card for the Admin Dashboard entry point.
///
/// Refactored to wrap inside StrokeCard for 2px Swan border, zero elevation,
/// and uses brand display fonts.
class AdminCommandCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  /// Overrides the card container background color. Defaults to [AppColors.seaSponge].
  final Color? overrideColor;

  /// Overrides the icon and icon-circle colors. Defaults to [AppColors.featherGreen].
  final Color? overrideIconColor;

  /// Overrides title, subtitle, and chevron colors. Defaults to [AppColors.eel].
  final Color? overrideTextColor;

  const AdminCommandCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.overrideColor,
    this.overrideIconColor,
    this.overrideTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    // Use beautiful brand pastels for default state or map the overrides cleanly
    final bgColor =
        overrideColor ?? (isLight ? AppColors.seaSponge : cs.primaryContainer);
    final iconColor =
        overrideIconColor ?? (isLight ? AppColors.featherGreen : cs.primary);
    final textColor = overrideTextColor ?? AppColors.eel;

    return StrokeCard(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
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
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.displayStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isLight
                        ? AppColors.wolf
                        : textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isLight ? AppColors.hare : textColor,
          ),
        ],
      ),
    );
  }
}
