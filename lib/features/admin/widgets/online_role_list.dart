import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../manager/role_manager.dart';
import '../model/role_dto.dart';

class OnlineRoleList extends StatelessWidget {
  final RoleManager manager;
  const OnlineRoleList({super.key, required this.manager});

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
                            Text('We couldn\'t load the latest data. Please check your internet connection and refresh.', style: Theme.of(context).textTheme.titleMedium),
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
