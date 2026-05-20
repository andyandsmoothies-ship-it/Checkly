import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/role_badge.dart';

/// Reusable card widget for displaying a user in the admin user list.
class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelf;
  final VoidCallback? onEdit;
  final VoidCallback? onResetPassword;
  final void Function(bool ban)? onBanToggle;

  const UserCard({
    super.key,
    required this.user,
    required this.isSelf,
    this.onEdit,
    this.onResetPassword,
    this.onBanToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'unknown';
    final isLocked = user['isLocked'] as bool? ?? false;
    final fullName = user['fullName'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;
    final canManage = GetIt.instance<PolicyManager>().can(
      AppCapabilities.usersManage,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fullName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'You',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      RoleBadge(role: role),
                      if (isLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Inactive',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Assignment info
                  if (user['storeName'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user['storeName'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                ],
              ),
            ),

            // 3-dot menu — hidden when user lacks users:manage
            if (canManage)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'reset_password') onResetPassword?.call();
                  if (value == 'toggle') onBanToggle?.call(!isLocked);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Role & Assignment'),
                  ),
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Text('Reset Password'),
                  ),
                  if (!isSelf)
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        isLocked ? 'Activate User' : 'Deactivate User',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
