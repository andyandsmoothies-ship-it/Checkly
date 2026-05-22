import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Standardized empty state widget used across Checkly.
///
/// Optionally accepts an [actionButton] widget (e.g. an ElevatedButton)
/// rendered below the subtitle as a call-to-action.
///
/// Refactored to use [AppColors.polar] background and bold Nunito labels.
class ChecklyEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? actionButton;
  final String? emoji;

  const ChecklyEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.emoji,
  });

  @override
  State<ChecklyEmptyState> createState() => ChecklyEmptyStateState();
}

class ChecklyEmptyStateState extends State<ChecklyEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  bool get isAnimating => _controller.isAnimating;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -0.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.1,
          end: 0.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.1,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jiggle() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    HapticFeedback.lightImpact();
    if (!reduceMotion) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget illustration = widget.emoji != null
        ? Text(widget.emoji!, style: const TextStyle(fontSize: 56))
        : Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.seaSponge,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.turtle, width: 2),
            ),
            child: Icon(widget.icon, size: 36, color: AppColors.featherGreen),
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.polar,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.swan, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _jiggle,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    );
                  },
                  child: illustration,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.wolf,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.actionButton != null) ...[
                const SizedBox(height: 24),
                widget.actionButton!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
