import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/admin_user_manager.dart';
import '../widgets/user_card.dart';
import '../widgets/user_create_sheet.dart';
import '../widgets/user_edit_sheet.dart';

final _di = GetIt.instance;

/// Admin: User Management — list, search, edit role/store/area, deactivate/reactivate.
class UserManagementPage extends StatefulWidget {
  final String? initialSearch;
  const UserManagementPage({super.key, this.initialSearch});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchController = TextEditingController();
  late final AdminUserManager _manager;
  String _selectedRole = 'all';

  static const _roleTabs = [
    ('all', 'All'),
    ('admin', 'Admin'),
    ('auditor', 'Auditor'),
    ('area_manager', 'Area Mgr'),
    ('store_manager', 'Store Mgr'),
  ];

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminUserManager>();
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _manager.load(search: _searchController.text.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() =>
      _manager.load(search: _searchController.text.trim());

  Future<void> _onSearch(String _) => _loadData();

  Future<void> _banUser(Map<String, dynamic> user, bool ban) async {
    if (ban) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate User?'),
          content: Text(
            'Are you sure you want to deactivate ${user['fullName']}? '
            'They will lose access to the system.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await _manager.banUser(user['id'] as String, ban: ban);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ban ? 'User deactivated' : 'User reactivated'),
            backgroundColor: ban
                ? Theme.of(context).colorScheme.error
                : AppTheme.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An unexpected issue occurred. Please check your connection or restart the app.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showEditSheet(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => UserEditSheet(
        user: user,
        areas: _manager.areas,
        loadStores: _manager.loadStores,
        onSave: ({required userId, fullName, role, storeId, areaId}) =>
            _saveUser(
              userId,
              fullName: fullName,
              role: role,
              storeId: storeId,
              areaId: areaId,
            ),
        onResetPassword: _showResetPasswordDialog,
      ),
    );
  }

  Future<void> _saveUser(
    String id, {
    String? fullName,
    String? role,
    String? storeId,
    String? areaId,
  }) async {
    Navigator.of(context).pop(); // Close sheet first

    try {
      await _manager.saveUser(
        id,
        fullName: fullName,
        role: role,
        storeId: storeId,
        areaId: areaId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on RootSuicideException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You cannot remove your own Admin role. '
              'Assign another Admin first.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } on TransferConflictException catch (e) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Transfer Required'),
          content: Text(
            'This position is currently held by ${e.existingManagerName}. '
            'Do you want to remove them and assign this user instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Transfer'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await _manager.saveUser(
            id,
            fullName: fullName,
            role: role,
            storeId: storeId,
            areaId: areaId,
            forceReassign: true,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transferred from ${e.existingManagerName}'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Transfer failed. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An unexpected issue occurred. Please check your connection or restart the app.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showResetPasswordDialog(
    BuildContext sheetCtx,
    String userId,
    String userName,
  ) {
    final passCtrl = TextEditingController();
    String? passError;

    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (dlgCtx, setDlgState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Set a new password for $userName'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      errorText: passError,
                      helperText: passError == null
                          ? 'Min 8 chars: uppercase, digit, special char'
                          : null,
                    ),
                    onChanged: (_) {
                      if (passError != null) {
                        setDlgState(() => passError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dlgCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final pass = passCtrl.text;
                    if (pass.isEmpty) {
                      setDlgState(() => passError = 'Password is required');
                      return;
                    }
                    try {
                      await _manager.resetPassword(userId, pass);
                      if (dlgCtx.mounted) {
                        Navigator.of(dlgCtx).pop(); // Close dialog
                        Navigator.of(sheetCtx).pop(); // Close edit sheet
                        ScaffoldMessenger.of(dlgCtx).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset successfully'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setDlgState(
                        () => passError =
                            'We couldn\'t reset the password. Please try again.',
                      );
                    }
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateUserSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => UserCreateSheet(
        areas: _manager.areas,
        loadStores: _manager.loadStores,
        onCreate:
            ({
              required email,
              required password,
              required fullName,
              required role,
              storeId,
              areaId,
            }) => _manager.createUser(
              email: email,
              password: password,
              fullName: fullName,
              role: role,
              storeId: storeId,
              areaId: areaId,
            ),
      ),
    );
    // createUser already prepends to users[] in the manager.
    // Only trigger a reload if the sheet returned true (create succeeded)
    // AND somehow the manager list is stale (defensive).
    if (created == true && mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserSheet,
        shape: const CircleBorder(),
        child: const Icon(Icons.person_add),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Role tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: _roleTabs.map((tab) {
                    final (role, label) = tab;
                    final count = role == 'all'
                        ? _manager.users.length
                        : _manager.users.where((u) => u['role'] == role).length;
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: WarmChip(
                        label: '$label ($count)',
                        selected: isSelected,
                        onTap: () => setState(() => _selectedRole = role),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Content
              Expanded(child: _buildBody(theme)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_manager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_manager.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load the latest data. Please check your internet connection and refresh.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _selectedRole == 'all'
        ? _manager.users
        : _manager.users.where((u) => u['role'] == _selectedRole).toList();

    if (filtered.isEmpty) {
      return const ChecklyEmptyState(
        icon: Icons.group_off,
        title: 'No users found',
        subtitle: 'Try adjusting your search or role filter.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => UserCard(
          user: filtered[index],
          isSelf: filtered[index]['id'] == _manager.currentUserId,
          onEdit: () => _showEditSheet(filtered[index]),
          onResetPassword: () => _showResetPasswordDialog(
            context,
            filtered[index]['id'] as String,
            filtered[index]['fullName'] as String? ?? 'this user',
          ),
          onBanToggle: (ban) => _banUser(filtered[index], ban),
        ),
      ),
    );
  }
}
