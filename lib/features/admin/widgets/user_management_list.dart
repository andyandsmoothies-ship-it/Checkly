import 'package:flutter/material.dart';

import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/admin_user_manager.dart';
import 'user_card.dart';

class UserManagementList extends StatelessWidget {
  final AdminUserManager manager;
  final String selectedRole;
  final Future<void> Function() onLoadData;
  final void Function(Map<String, dynamic> user) onEdit;
  final void Function(BuildContext context, String userId, String userName)
  onResetPassword;
  final void Function(Map<String, dynamic> user, bool ban) onBanToggle;

  const UserManagementList({
    super.key,
    required this.manager,
    required this.selectedRole,
    required this.onLoadData,
    required this.onEdit,
    required this.onResetPassword,
    required this.onBanToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (manager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (manager.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load the latest data. Please check your internet connection and refresh.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onLoadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = selectedRole == 'all'
        ? manager.users
        : manager.users.where((u) => u['role'] == selectedRole).toList();

    if (filtered.isEmpty) {
      return const ChecklyEmptyState(
        emoji: '👥',
        title: "Let's find some team members!",
        subtitle:
            'Try adjusting your search or selection filter to find users.',
      );
    }

    return RefreshIndicator(
      onRefresh: onLoadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final user = filtered[index];
          return UserCard(
            user: user,
            isSelf: user['id'] == manager.currentUserId,
            onEdit: () => onEdit(user),
            onResetPassword: () => onResetPassword(
              context,
              user['id'] as String,
              user['fullName'] as String? ?? 'this user',
            ),
            onBanToggle: (ban) => onBanToggle(user, ban),
          );
        },
      ),
    );
  }
}
