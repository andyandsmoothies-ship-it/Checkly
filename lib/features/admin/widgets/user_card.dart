import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/role_badge.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/primitives.dart';

/// Reusable card widget for displaying a user in the administrative lists.
/// Leverages the unified [UniversalListCard] primitive structure.
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
    final canManage = GetIt.instance<PolicyManager>().can(
      AppCapabilities.usersManage,
    );

    return UniversalListCard(
      title: fullName,
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onEdit,
      leading: PastelAvatar(name: fullName, role: role, size: 44.0),
      subtitle: email,
      subtitleWidget: user['storeName'] != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.store, size: 13, color: AppColors.wolf),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      user['storeName'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.wolf,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : null,
      badges: [
        RoleBadge(role: role),
        if (isLocked) const PillChip(label: 'Inactive', type: PillChipType.red),
        if (isSelf) const PillChip(label: 'You', type: PillChipType.blue),
      ],
      trailing: canManage
          ? PopupMenuButton<String>(
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
                    child: Text(isLocked ? 'Activate User' : 'Deactivate User'),
                  ),
              ],
            )
          : null,
    );
  }
}
