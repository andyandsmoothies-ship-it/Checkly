import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A bubbly, gamified progress bar designed for gamification objectives.
///
/// Features standard Macaw Blue filling, solid Swan border detailing, and an implicit
/// animation system to smoothly transition between progress values. Renders an inner
/// gloss highlight reflection on top of the bar for high-fidelity polished aesthetics.
class QuestProgressBar extends StatelessWidget {
  final double value; // Clamped internally between 0.0 and 1.0
  final double height;
  final Color? backgroundColor;
  final Color? fillColor;
  final Color? borderColor;

  const QuestProgressBar({
    super.key,
    required this.value,
    this.height = 16.0,
    this.backgroundColor,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Standard theme alignments
    final barBgColor =
        backgroundColor ?? (isLight ? AppColors.polar : AppColors.charcoal);
    final barFillColor = fillColor ?? AppColors.macaw;
    final barBorderColor =
        borderColor ??
        (isLight ? AppColors.swan : AppColors.swan.withAlpha(40));

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: barBorderColor, width: 2.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final fillWidth = maxWidth * clampedValue;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Smooth implicitly animated fill container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: fillWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: barFillColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Gamified inner gloss highlight reflection (adds premium 3D bubbly flavor)
              if (clampedValue > 0.05)
                Positioned(
                  top: 2,
                  left: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: fillWidth > 12 ? fillWidth - 8 : 4,
                    height: height * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(height / 8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
