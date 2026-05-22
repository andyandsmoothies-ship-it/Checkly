import 'dart:async';
import 'package:flutter/material.dart';

/// A wrapper widget that animates its children using a staggered "domino" entrance effect.
///
/// Each child fades in and slides up from 30px below one after another.
/// Respects accessibility and reduced motion preferences by instantly displaying
/// children without animations if requested.
class BouncyListWrapper extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const BouncyListWrapper({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      controller: controller,
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        // Calculate stagger delay: index * 40ms, capped at 500ms
        final delayMs = (index * 40).clamp(0, 500);
        final delay = Duration(milliseconds: delayMs);

        return StaggeredListItem(delay: delay, child: child);
      },
    );
  }
}

/// A widget that wraps a single list child and animates its opacity and vertical offset
/// after a specified stagger delay.
class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem> {
  double _targetValue = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _targetValue = 1.0;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          setState(() {
            _targetValue = 1.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final double target = reducedMotion ? 1.0 : _targetValue;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: target),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final double opacity = reducedMotion ? 1.0 : value;
        final double yOffset = reducedMotion ? 0.0 : 30.0 * (1.0 - value);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0.0, yOffset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
