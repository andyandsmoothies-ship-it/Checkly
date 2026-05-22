import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../manager/admin_user_manager.dart';
import '../widgets/user_create_sheet.dart';
import '../widgets/user_edit_sheet.dart';
import '../widgets/user_management_dialogs.dart';
import '../widgets/user_management_list.dart';

final _di = GetIt.instance;

/// Admin: User Management — list, search, edit role/store, deactivate/reactivate.
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
      final confirmed = await UserManagementDialogs.confirmDeactivate(
        context,
        user,
      );
      if (!confirmed) return;
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
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    }
  }

  void _showEditSheet(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => UserEditSheet(
        user: user,
        loadStores: _manager.loadStores,
        onSave:
            ({required userId, fullName, role, storeId, assignedStoreIds}) =>
                _saveUser(
                  userId,
                  fullName: fullName,
                  role: role,
                  storeId: storeId,
                  assignedStoreIds: assignedStoreIds,
                ),
        onResetPassword: (sheetCtx, userId, userName) =>
            UserManagementDialogs.showResetPasswordDialog(
              sheetCtx: sheetCtx,
              userId: userId,
              userName: userName,
              manager: _manager,
            ),
      ),
    );
  }

  Future<void> _saveUser(
    String id, {
    String? fullName,
    String? role,
    String? storeId,
    List<String>? assignedStoreIds,
  }) async {
    Navigator.of(context).pop(); // Close sheet first

    try {
      await _manager.saveUser(
        id,
        fullName: fullName,
        role: role,
        storeId: storeId,
        assignedStoreIds: assignedStoreIds,
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
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'root_suicide',
            message:
                'You cannot remove your own Admin role. Assign another Admin first.',
          ),
        );
      }
    } on TransferConflictException catch (e) {
      if (!mounted) return;
      final confirmed = await UserManagementDialogs.confirmTransfer(
        context,
        e.existingManagerName,
      );

      if (confirmed == true && mounted) {
        try {
          await _manager.saveUser(
            id,
            fullName: fullName,
            role: role,
            storeId: storeId,
            assignedStoreIds: assignedStoreIds,
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
        } on DioException catch (e) {
          _di<ErrorDisplayService>().show(AppError.fromDioException(e));
        } catch (_) {
          _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
        }
      }
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    }
  }

  Future<void> _showCreateUserSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => UserCreateSheet(
        loadStores: _manager.loadStores,
        onCreate:
            ({
              required email,
              required password,
              required fullName,
              required role,
              storeId,
              assignedStoreIds,
              forceReassign,
            }) => _manager.createUser(
              email: email,
              password: password,
              fullName: fullName,
              role: role,
              storeId: storeId,
              assignedStoreIds: assignedStoreIds,
              forceReassign: forceReassign ?? false,
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
    final canManage = _di<PolicyManager>().can(AppCapabilities.usersManage);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showCreateUserSheet,
              tooltip: 'Add User',
            ),
        ],
      ),
      floatingActionButton: null,
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
              Expanded(
                child: UserManagementList(
                  manager: _manager,
                  selectedRole: _selectedRole,
                  onLoadData: _loadData,
                  onEdit: _showEditSheet,
                  onResetPassword: (context, userId, userName) =>
                      UserManagementDialogs.showResetPasswordDialog(
                        sheetCtx: context,
                        userId: userId,
                        userName: userName,
                        manager: _manager,
                      ),
                  onBanToggle: _banUser,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
