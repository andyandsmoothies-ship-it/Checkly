import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/services/connectivity_service.dart';
import '../manager/role_manager.dart';
import '../model/role_dto.dart';

final _di = GetIt.instance;

/// Displays all system roles with their capability count.
///
/// Enforces the Online-Only Mandate (ADR Option A):
/// If the device is offline, renders a full-page lock screen — no stale data shown.
class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  late final RoleManager _manager;
  late final ConnectivityService _connectivity;

  @override
  void initState() {
    super.initState();
    _manager = _di<RoleManager>();
    _connectivity = _di<ConnectivityService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_connectivity.isOnline) {
        _manager.loadRoles();
        _manager.loadCatalog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _manager.isLoading,
            builder: (_, loading, _) => loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _connectivity.isOnline
                        ? () {
                            _manager.loadRoles();
                            _manager.loadCatalog();
                          }
                        : null,
                  ),
          ),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: _connectivity.onConnectivityChanged,
        initialData: _connectivity.isOnline,
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? _connectivity.isOnline;
          if (!isOnline) return const _OfflineLockView();
          return _OnlineRoleList(manager: _manager);
        },
      ),
    );
  }
}

class _OnlineRoleList extends StatelessWidget {
  final RoleManager manager;
  const _OnlineRoleList({required this.manager});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RoleDto>?>(
      valueListenable: manager.roles,
      builder: (context, roles, _) {
        return ValueListenableBuilder<List<String>?>(
          valueListenable: manager.catalog,
          builder: (context, catalog, _) {
            final totalStr = catalog != null && catalog.isNotEmpty ? '/${catalog.length}' : '';
            return ValueListenableBuilder<bool>(
              valueListenable: manager.isLoading,
              builder: (context, isLoading, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: manager.error,
              builder: (context, error, _) {
                if (isLoading && roles == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (error != null && roles == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Failed to load roles', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(error, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            manager.loadRoles();
                            manager.loadCatalog();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (roles == null || roles.isEmpty) {
                  return const Center(child: Text('No roles found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: roles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final role = roles[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          role.role,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${role.capabilities.length}$totalStr capabilities assigned',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin/roles/${role.role}'),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
      },
    );
  }
}

/// Full-page lock screen shown when the device is offline.
/// Satisfies AT-01: no role data is shown; only the wifi_off icon and message.
class _OfflineLockView extends StatelessWidget {
  const _OfflineLockView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Requires Stable Internet Connection',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Role management is online-only to prevent stale security state.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
