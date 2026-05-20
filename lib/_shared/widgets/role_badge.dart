import 'package:flutter/material.dart';

import '../constants/app_roles.dart';

enum RoleBadgeSize { small, medium }

/// A unified badge for displaying user roles across the application.
class RoleBadge extends StatelessWidget {
  final String role;
  final RoleBadgeSize size;

  const RoleBadge({
    super.key,
    required this.role,
    this.size = RoleBadgeSize.small,
  });

  static Color _getRoleColor(String role, ThemeData theme) {
    return switch (role) {
      AppRoles.admin => theme.colorScheme.tertiary,
      AppRoles.auditor => theme.colorScheme.primary,
      AppRoles.storeManager => theme.colorScheme.secondary,
      AppRoles.areaManager => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }

  static String _getRoleLabel(String role) {
    return switch (role) {
      AppRoles.admin => 'Admin',
      AppRoles.auditor => 'Auditor',
      AppRoles.storeManager => 'Store Mgr',
      AppRoles.areaManager => 'Area Mgr',
      _ => role,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getRoleColor(role, theme);
    final label = _getRoleLabel(role);

    final isSmall = size == RoleBadgeSize.small;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 4);

    final baseStyle = isSmall
        ? theme.textTheme.labelSmall
        : theme.textTheme.labelMedium;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      child: Text(
        label,
        style: baseStyle?.copyWith(color: color, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
