import 'package:flutter/material.dart';

/// SC-4: Extracted from main_shell.dart — reusable bottom nav item widget.
/// Used by MainShell for each tab. INBOX tab gets a badge count overlay.
class NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem> {
  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final curve = reducedMotion ? Curves.linear : const ElasticOutCurve(0.6);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    final color = widget.isActive
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSlide(
                offset: widget.isActive ? const Offset(0, -0.25) : Offset.zero,
                duration: duration,
                curve: curve,
                child: AnimatedScale(
                  scale: widget.isActive ? 1.2 : 1.0,
                  duration: duration,
                  curve: curve,
                  child: Icon(widget.icon, size: 24, color: color),
                ),
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 14,
                    ),
                    child: Text(
                      widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
