import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

/// Animated skeleton loading item for store detail list view.
/// Automatically handles ticker updates and respects user reduced motion settings.
class StoreDetailSkeleton extends StatefulWidget {
  final Color? backgroundColor;

  const StoreDetailSkeleton({
    super.key,
    this.backgroundColor,
  });

  @override
  State<StoreDetailSkeleton> createState() => _StoreDetailSkeletonState();
}

class _StoreDetailSkeletonState extends State<StoreDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine default background color if none provided
    final defaultBg = isDark ? AppColors.eel : AppColors.polar;
    final skeletonBg = widget.backgroundColor ?? defaultBg;
    final pulseColor = isDark ? AppColors.hare : AppColors.swan;

    if (disableAnimations) {
      return StrokeCard(
        color: skeletonBg,
        borderColor: AppColors.swan,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pulseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 150, color: pulseColor),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: pulseColor),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.5),
          child: StrokeCard(
            color: skeletonBg,
            borderColor: AppColors.swan,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pulseColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 150, color: pulseColor),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: pulseColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
