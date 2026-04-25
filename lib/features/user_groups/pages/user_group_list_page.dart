import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../manager/user_group_manager.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/user_group_tile.dart';

final _di = GetIt.instance;

/// Admin-only page for listing and creating User Groups.
///
/// Capability gate: users without [AppCapabilities.usersManage]
/// are redirected to `/home` on load.
///
/// 4-state handling:
/// - Loading: [CircularProgressIndicator]
/// - Empty: empty state with FAB to create first group
/// - Error: error card with retry button
/// - Success: [ListView] of [_UserGroupTile] items
class UserGroupListPage extends StatefulWidget {
  const UserGroupListPage({super.key});

  @override
  State<UserGroupListPage> createState() => _UserGroupListPageState();
}

class _UserGroupListPageState extends State<UserGroupListPage> {
  late final UserGroupManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<UserGroupManager>();

    // Capability gate — redirect if not authorized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_di<PolicyManager>().can(AppCapabilities.usersManage)) {
        context.go('/home');
        return;
      }
      _manager.loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Groups'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        tooltip: 'Create a new user group',
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_manager.error != null) {
            return ErrorState(
              message: _manager.error!,
              onRetry: _manager.loadGroups,
            );
          }

          if (_manager.groups.isEmpty) {
            return EmptyState(onCreate: () => _showCreateSheet(context));
          }

          return RefreshIndicator(
            onRefresh: _manager.loadGroups,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _manager.groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => UserGroupTile(group: _manager.groups[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateGroupSheet(manager: _manager),
    );
  }
}
