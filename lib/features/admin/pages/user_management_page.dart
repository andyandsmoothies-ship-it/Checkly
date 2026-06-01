import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
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
      enableDrag: false,
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
    Navigator.maybePop(context); // Close sheet first

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
      enableDrag: false,
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
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              key: const Key('create_user_fab'),
              tooltip: 'Add User',
              backgroundColor: AppColors.featherGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              onPressed: _showCreateUserSheet,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: AppColors.eel,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppColors.wolf,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.wolf),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.wolf),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.swan, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.featherGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Role dropdown filter pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    DropdownFilterPill(
                      label: 'Role',
                      value: switch (_selectedRole) {
                        'all' => 'All',
                        'admin' => 'Admin',
                        'auditor' => 'Auditor',
                        'area_manager' => 'Area Mgr',
                        'store_manager' => 'Store Mgr',
                        _ => _selectedRole,
                      },
                      active: _selectedRole != 'all',
                      onTap: () => showUserRoleFilterSheet(
                        context: context,
                        currentFilter: _selectedRole,
                        countByRole: (role) {
                          if (role == 'all') return _manager.users.length;
                          return _manager.users.where((u) => u['role'] == role).length;
                        },
                        onSelected: (val) => setState(() => _selectedRole = val),
                      ),
                    ),
                  ],
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

class DropdownFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const DropdownFilterPill({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(
                color: active ? Colors.white : AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.eel,
            ),
          ],
        ),
      ),
    );
  }
}

void showUserRoleFilterSheet({
  required BuildContext context,
  required String currentFilter,
  required int Function(String) countByRole,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final roles = [
        {'id': 'all', 'label': 'All Users', 'count': countByRole('all')},
        {'id': 'admin', 'label': 'Admin', 'count': countByRole('admin')},
        {'id': 'auditor', 'label': 'Auditor', 'count': countByRole('auditor')},
        {'id': 'area_manager', 'label': 'Area Manager', 'count': countByRole('area_manager')},
        {'id': 'store_manager', 'label': 'Store Manager', 'count': countByRole('store_manager')},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Role',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...roles.map((role) {
                final isSelected = currentFilter == role['id'];
                return InkWell(
                  onTap: () {
                    onSelected(role['id'] as String);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.featherGreen.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              role['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.featherGreen : AppColors.eel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.featherGreen
                                    : AppColors.swan.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${role['count']}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.eel.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
