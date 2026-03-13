import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../auth/manager/auth_manager.dart';
import '../../stores/services/store_api_service.dart';
import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// Admin: User Management — list, search, edit role/store/area, ban/unban.
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  String? _error;

  String get _currentUserId => _di<AuthManager>().currentUser?.userId ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final usersFuture = _di<AdminApiService>().getUsers(
        search: search.isEmpty ? null : search,
      );
      final areasFuture = _loadAreas();
      final storesFuture = _loadStores();

      final users = await usersFuture;
      final areas = await areasFuture;
      final stores = await storesFuture;

      if (!mounted) return;
      setState(() {
        _users = users;
        _areas = areas;
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAreas() async {
    final dio = _di<Dio>();
    final response = await dio.get('/areas');
    final list = response.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _loadStores() async {
    final stores = await _di<StoreApiService>().getStores();
    return stores
        .map((s) => <String, dynamic>{'id': s.id, 'name': s.name})
        .toList();
  }

  Future<void> _onSearch(String _) async {
    await _loadData();
  }

  Future<void> _banUser(Map<String, dynamic> user, bool ban) async {
    try {
      await _di<AdminApiService>().banUser(user['id'] as String, ban: ban);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ban ? 'User banned' : 'User unbanned'),
            backgroundColor: ban ? Colors.red : AppTheme.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditSheet(Map<String, dynamic> user) {
    String? selectedRole = user['role'] as String?;
    String? selectedStoreId = user['storeId'] as String?;
    String? selectedAreaId = user['areaId'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    user['fullName'] ?? 'Unknown',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user['email'] ?? '',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'auditor',
                        child: Text('Auditor'),
                      ),
                      DropdownMenuItem(
                        value: 'store_manager',
                        child: Text('Store Manager'),
                      ),
                      DropdownMenuItem(
                        value: 'area_manager',
                        child: Text('Area Manager'),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => selectedRole = v),
                  ),
                  const SizedBox(height: 12),

                  // Store dropdown (relevant for SM)
                  DropdownButtonFormField<String>(
                    value: _stores.any((s) => s['id'] == selectedStoreId)
                        ? selectedStoreId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Store',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ..._stores.map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => selectedStoreId = v),
                  ),
                  const SizedBox(height: 12),

                  // Area dropdown (relevant for AM)
                  DropdownButtonFormField<String>(
                    value: _areas.any((a) => a['id'] == selectedAreaId)
                        ? selectedAreaId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Area',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ..._areas.map(
                        (a) => DropdownMenuItem(
                          value: a['id'] as String,
                          child: Text(a['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => selectedAreaId = v),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _saveUser(
                        user['id'] as String,
                        role: selectedRole,
                        storeId: selectedStoreId,
                        areaId: selectedAreaId,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveUser(
    String id, {
    String? role,
    String? storeId,
    String? areaId,
  }) async {
    Navigator.of(context).pop(); // Close sheet first

    try {
      await _di<AdminApiService>().updateUser(
        id,
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
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
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

          // Content
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Failed to load users', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _users.length,
        itemBuilder: (context, index) => _UserCard(
          user: _users[index],
          isSelf: _users[index]['id'] == _currentUserId,
          onTap: () => _showEditSheet(_users[index]),
          onBanToggle: (ban) => _banUser(_users[index], ban),
        ),
      ),
    );
  }
}

// ─── User Card ───

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelf;
  final VoidCallback onTap;
  final void Function(bool ban) onBanToggle;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onTap,
    required this.onBanToggle,
  });

  static const _roleColors = <String, Color>{
    'admin': Colors.deepPurple,
    'auditor': Colors.blue,
    'store_manager': Colors.teal,
    'area_manager': Colors.orange,
  };

  static const _roleLabels = <String, String>{
    'admin': 'Admin',
    'auditor': 'Auditor',
    'store_manager': 'Store Manager',
    'area_manager': 'Area Manager',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = user['role'] as String? ?? 'unknown';
    final isLocked = user['isLocked'] as bool? ?? false;
    final fullName = user['fullName'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;
    final roleColor = _roleColors[role] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    Row(
                      children: [
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _roleLabels[role] ?? role,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Banned',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Ban toggle (disabled for self)
              if (!isSelf)
                IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock_open : Icons.block,
                    color: isLocked ? AppTheme.success : Colors.red,
                  ),
                  tooltip: isLocked ? 'Unban user' : 'Ban user',
                  onPressed: () => onBanToggle(!isLocked),
                ),

              // Edit chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
