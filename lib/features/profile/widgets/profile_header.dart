import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

class ProfileHeader extends StatelessWidget {
  final String initials;
  final String email;
  final String role;

  const ProfileHeader({
    super.key,
    required this.initials,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(role, theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: AppFonts.serifStyle(
                    fontSize: theme.textTheme.titleSmall?.fontSize ?? 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role, ThemeData theme) => switch (role) {
    'admin' => theme.colorScheme.error,
    'auditor' => theme.colorScheme.primary,
    'store_manager' => theme.colorScheme.secondary,
    'area_manager' => theme.colorScheme.tertiary,
    _ => theme.colorScheme.primary,
  };

  String _roleLabel(String role) => switch (role) {
    'admin' => 'ADMIN',
    'auditor' => 'AUDITOR',
    'store_manager' => 'STORE MANAGER',
    'area_manager' => 'AREA MANAGER',
    _ => role.toUpperCase(),
  };
}
