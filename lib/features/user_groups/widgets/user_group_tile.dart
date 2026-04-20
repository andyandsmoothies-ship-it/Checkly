import 'package:flutter/material.dart';
import '../model/user_group_dto.dart';

class UserGroupTile extends StatelessWidget {
  final UserGroupDto group;
  const UserGroupTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.group, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: group.description != null && group.description!.isNotEmpty
            ? Text(
                group.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
