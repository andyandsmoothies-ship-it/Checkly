import 'package:flutter/material.dart';

/// Prominent CCP/RISK toggle button (PWA-style).
class AuditCcpRiskButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const AuditCcpRiskButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
      ),
      selected: active,
      selectedColor: activeColor,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
      ),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: active ? activeColor : Colors.transparent),
      ),
      onSelected: (_) => onTap(),
    );
  }
}
