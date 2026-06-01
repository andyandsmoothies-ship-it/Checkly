import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/checkly_theme_tokens.dart';

enum PillChipType { green, blue, red, yellow, purple }

/// A fully rounded, pill-shaped chip styled with light pastel backgrounds.
///
/// Ensures compliance with Checkly's gamified visual system by using specific
/// high-contrast brand accents for borders and text, avoiding standard dull grays.
class PillChip extends StatelessWidget {
  final String label;
  final PillChipType type;
  final Widget? icon;
  final VoidCallback? onTap;

  const PillChip({
    super.key,
    required this.label,
    this.type = PillChipType.green,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    // Resolve dynamic cardBorderWidth from design tokens
    final tokens = Theme.of(context).extension<ChecklyThemeTokens>();
    final resolvedBorderWidth = tokens?.cardBorderWidth ?? 2.0;

    switch (type) {
      case PillChipType.green:
        backgroundColor = AppColors.seaSponge;
        textColor = const Color(0xFF388E3C);
        borderColor = AppColors.turtle;
        break;
      case PillChipType.blue:
        backgroundColor = AppColors.iguana;
        textColor = AppColors.humpback;
        borderColor = AppColors.blueJay;
        break;
      case PillChipType.red:
        backgroundColor = AppColors.walkingFish;
        textColor = AppColors.cardinal;
        borderColor = AppColors.flamingo;
        break;
      case PillChipType.yellow:
        backgroundColor = AppColors.canary;
        textColor = AppColors.fox;
        borderColor = AppColors.duck;
        break;
      case PillChipType.purple:
        backgroundColor = const Color(0xFFFBE4FF);
        textColor = AppColors.beetle;
        borderColor = AppColors.starfish;
        break;
    }

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: resolvedBorderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
      );
    }

    return child;
  }
}
