import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// A custom check box that performs a playful elastic scale-up pop
/// when checked, accompanied by tactile haptic feedback.
class BouncyCheckbox extends StatefulWidget {
  final bool isChecked;
  final ValueChanged<bool>? onChanged;
  final double size;

  const BouncyCheckbox({
    super.key,
    required this.isChecked,
    this.onChanged,
    this.size = 28.0,
  });

  @override
  State<BouncyCheckbox> createState() => BouncyCheckboxState();
}

class BouncyCheckboxState extends State<BouncyCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isAnimating = false;

  bool get isAnimating => _isAnimating;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });

    // Initialize controller to the end so it renders at scale 1.0 initially
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant BouncyCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked && widget.isChecked) {
      _triggerPopAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerPopAnimation() {
    if (MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    if (mounted) {
      setState(() {
        _isAnimating = true;
      });
      _controller.forward(from: 0.0);
    }
  }

  void _handleTap() {
    if (widget.onChanged != null) {
      final newValue = !widget.isChecked;
      widget.onChanged!(newValue);

      if (newValue) {
        HapticFeedback.mediumImpact();
        _triggerPopAnimation();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: widget.isChecked,
      enabled: widget.onChanged != null,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: widget.onChanged != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 150),
            child: _isAnimating
                ? AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildCheckboxBody(),
                      );
                    },
                  )
                : _buildCheckboxBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxBody() {
    final checkedColor = AppColors.featherGreen;
    final uncheckedBorderColor = AppColors.swan;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.isChecked ? checkedColor : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: widget.isChecked ? checkedColor : uncheckedBorderColor,
          width: 2.0,
        ),
      ),
      child: widget.isChecked
          ? Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: widget.size * 0.7,
                key: const ValueKey('check_icon'),
              ),
            )
          : null,
    );
  }
}
