import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/role_badge.dart';

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
                RoleBadge(role: role, size: RoleBadgeSize.medium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
