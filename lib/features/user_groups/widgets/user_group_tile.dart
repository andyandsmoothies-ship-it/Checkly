import 'package:flutter/material.dart';
import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/widgets/primitives/primitives.dart';
import '../model/user_group_dto.dart';

/// Reusable list tile/card widget for user groups.
/// Migrated to leverage the unified [UniversalListCard] layout primitive.
class UserGroupTile extends StatelessWidget {
  final UserGroupDto group;
  final VoidCallback? onTap;

  const UserGroupTile({super.key, required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return UniversalListCard(
      title: group.name,
      titleStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      ),
      subtitle: (group.description != null && group.description!.isNotEmpty)
          ? group.description
          : null,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isLight
            ? AppColors.iguana
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        child: const Icon(Icons.group, color: AppColors.macaw, size: 20),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
