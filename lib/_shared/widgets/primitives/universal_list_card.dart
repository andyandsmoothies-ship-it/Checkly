import 'package:flutter/material.dart';
import 'stroke_card.dart';
import '../../theme/app_colors.dart';

/// A standardized list item card primitive that enforces consistent layout,
/// typography, icon boundary sizes, and action slots across Checkly.
///
/// Wraps the highly-interactive [StrokeCard] to provide 2px solid border,
/// tap scaling squash micro-interactions, and premium tactile feedback.
class UniversalListCard extends StatelessWidget {
  /// Optional leading widget on the left side (e.g., PastelAvatar or styled Icon container).
  /// Enforces uniform boundary sizes (44x44 px) to align adjacent list items.
  final Widget? leading;

  /// The main card header text.
  final String title;

  /// Custom text style for the title. If null, defaults to Nunito titleSmall
  /// with a bold w700 weight.
  final TextStyle? titleStyle;

  /// Optional secondary text detail beneath the title.
  final String? subtitle;

  /// Optional custom subtitle widget for advanced layouts (e.g. unassigned alerts).
  final Widget? subtitleWidget;

  /// List of badges or chips displayed beneath the description (e.g. PillChip).
  final List<Widget>? badges;

  /// Action widget on the far right (e.g. Chevron icon or 3-dot PopupMenuButton).
  final Widget? trailing;

  /// Tactile tap callback. Triggers light haptic feedback and squash scaling.
  final VoidCallback? onTap;

  /// Optional override for the card background color.
  final Color? color;

  /// Optional override for the card border color.
  final Color? borderColor;

  /// Optional custom padding inside the card. Defaults to 12.0 padding on all sides.
  final EdgeInsetsGeometry? padding;

  /// Optional custom margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Double value for border corner radius. Defaults to 16.0.
  final double borderRadius;

  const UniversalListCard({
    super.key,
    required this.title,
    this.leading,
    this.titleStyle,
    this.subtitle,
    this.subtitleWidget,
    this.badges,
    this.trailing,
    this.onTap,
    this.color,
    this.borderColor,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrokeCard(
      color: color,
      borderColor: borderColor,
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(12),
      margin: margin,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enforce 44x44 bounding slot on the left for consistent list alignment
          if (leading != null) ...[
            SizedBox(width: 44, height: 44, child: Center(child: leading!)),
            const SizedBox(width: 12),
          ],

          // Central content column holding Title, Subtitle, and Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.wolf,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 4),
                  subtitleWidget!,
                ],
                if (badges != null && badges!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 4, children: badges!),
                ],
              ],
            ),
          ),

          // Trailing slot for standard chevrons or interactive menus
          if (trailing != null) ...[
            const SizedBox(width: 8),
            // Center the trailing widget vertically with the first line if start-aligned
            Padding(padding: const EdgeInsets.only(top: 2), child: trailing!),
          ],
        ],
      ),
    );
  }
}
