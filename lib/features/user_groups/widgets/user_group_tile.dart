import 'package:flutter/material.dart';
import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import '../model/user_group_dto.dart';

class UserGroupTile extends StatelessWidget {
  final UserGroupDto group;
  const UserGroupTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return StrokeCard(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isLight
              ? AppColors.iguana
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
          child: const Icon(Icons.group, color: AppColors.macaw, size: 20),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
          ),
        ),
        subtitle: group.description != null && group.description!.isNotEmpty
            ? Text(
                group.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Nunito'),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
