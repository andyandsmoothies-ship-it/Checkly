import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// A flat card widget with rounded corners and a prominent 2px Swan border.
///
/// Fully encapsulates the Checkly gamified look: zero elevation, high-contrast borders,
/// and rounded styling (R: 16px). Supports a custom background color, margin, padding,
/// and an interactive splash animation when [onTap] is provided.
class StrokeCard extends StatefulWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const StrokeCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  State<StrokeCard> createState() => _StrokeCardState();
}

class _StrokeCardState extends State<StrokeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor =
        widget.color ??
        (isLight
            ? AppColors.snow
            : Theme.of(context).cardTheme.color ?? Colors.transparent);
    final borderCol =
        widget.borderColor ??
        (isLight ? AppColors.swan : AppColors.swan.withAlpha(40));

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      side: BorderSide(color: borderCol, width: 2.0),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Card(
            elevation: 0,
            margin: widget.margin ?? EdgeInsets.zero,
            color: cardColor,
            shape: cardShape,
            clipBehavior: Clip
                .antiAlias, // Ensures the splash doesn't bleed out of the rounded corners
            child: InkWell(
              onTap: widget.onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: widget.margin ?? EdgeInsets.zero,
      color: cardColor,
      shape: cardShape,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16.0),
        child: widget.child,
      ),
    );
  }
}
