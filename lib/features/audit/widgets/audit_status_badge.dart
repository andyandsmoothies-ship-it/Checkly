import 'package:flutter/material.dart';

/// Small colored badge for status indicators on the compact row.
class AuditStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AuditStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: icon == null
          ? Text(label, style: textStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: (textStyle.fontSize ?? 12) + 2,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(label, style: textStyle),
              ],
            ),
    );
  }
}
