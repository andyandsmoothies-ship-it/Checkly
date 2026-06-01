import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/checkly_theme_tokens.dart';

/// A playful, bubbly 3D button widget designed to match the gamified reskin.
///
/// Features a prominent solid bottom border in a darker shade of the fill color
/// to create a realistic 3D appearance. When pressed, the button physically
/// shifts down by 4 pixels, mimicking the signature tactile feedback of Duolingo.
class BubblyButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final bool isLoading;
  final double height;
  final bool isOutline;

  const BubblyButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.height = 50.0,
    this.isOutline = false,
  }) : assert(
         label != null || child != null,
         'Either label or child must be provided',
       );

  @override
  State<BubblyButton> createState() => _BubblyButtonState();
}

class _BubblyButtonState extends State<BubblyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Resolve our active design tokens from theme, with safe fallback to Duolingo defaults
    final tokens = Theme.of(context).extension<ChecklyThemeTokens>();
    final cardRadius = tokens?.cardRadius ?? 16.0;
    final depth3d = tokens?.button3dDepth ?? 4.0;
    final borderWidth = tokens?.cardBorderWidth ?? 2.0;

    // Resolve base button color: fallback to primary seed (featherGreen) or swan if disabled
    final baseColor =
        widget.color ??
        (isEnabled
            ? AppColors.featherGreen
            : (isLight ? AppColors.swan : AppColors.charcoal));

    // Dynamically generate the darker 3D shadow color by lerping toward black
    final shadowColor = widget.isOutline
        ? (Color.lerp(baseColor, Colors.black, 0.1) ?? baseColor)
        : (Color.lerp(baseColor, Colors.black, 0.25) ?? baseColor.withAlpha(200));

    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color:
          widget.textColor ??
          (widget.isOutline
              ? (isEnabled ? baseColor : (isLight ? AppColors.wolf : AppColors.hare))
              : (isEnabled
                  ? Colors.white
                  : (isLight ? AppColors.wolf : AppColors.hare))),
    );

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final positionDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 50);
    final scaleDuration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 100);
    final scaleCurve = _isPressed ? Curves.easeOut : Curves.easeOutBack;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: SizedBox(
        height: widget.height + depth3d, // Base height + 3D shadow depth token
        width: double.infinity,
        child: Stack(
          children: [
            // The 3D Shadow/Background Layer (only rendered if depth > 0)
            if (depth3d > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: depth3d,
                child: Container(
                  decoration: BoxDecoration(
                    color: shadowColor,
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                ),
              ),
            // The Interactive Button Face Layer
            AnimatedPositioned(
              duration: positionDuration,
              left: 0,
              right: 0,
              top: _isPressed ? depth3d : 0,
              bottom: _isPressed ? 0 : depth3d,
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : 1.0,
                duration: scaleDuration,
                curve: scaleCurve,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isOutline ? Colors.white : baseColor,
                    border: widget.isOutline
                        ? Border.all(color: baseColor, width: borderWidth)
                        : null,
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isOutline ? baseColor : Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                const SizedBox(width: 8),
                              ],
                              if (widget.child != null)
                                widget.child!
                              else if (widget.label != null)
                                Text(widget.label!, style: textStyle),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
