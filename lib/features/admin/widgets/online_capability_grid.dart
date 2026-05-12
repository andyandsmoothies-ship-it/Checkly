import 'package:flutter/material.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/constants/capability_dictionary.dart';
import '../manager/role_manager.dart';
import '../model/role_dto.dart';
import '../services/admin_api_service.dart';

class OnlineCapabilityGrid extends StatelessWidget {
  final String role;
  final RoleManager manager;
  final String? mutatingCapability;
  final bool canManage;
  final Future<void> Function({
    required String capability,
    required bool currentlyAssigned,
  })
  onToggle;

  const OnlineCapabilityGrid({
    super.key,
    required this.role,
    required this.manager,
    required this.mutatingCapability,
    required this.canManage,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, CapabilityMeta>?>(
      valueListenable: manager.catalogMeta,
      builder: (context, catalogMeta, _) {
        return ValueListenableBuilder<List<String>?>(
          valueListenable: manager.catalog,
          builder: (context, catalog, _) {
            return ValueListenableBuilder<List<RoleDto>?>(
              valueListenable: manager.roles,
              builder: (context, roles, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: manager.isLoading,
                  builder: (context, isLoading, _) {
                    if (isLoading && roles == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final thisRole = roles
                        ?.where((r) => r.role == role)
                        .firstOrNull;
                    final assigned = thisRole?.capabilities ?? [];
                    final allCapabilities = catalog ?? assigned;

                    if (allCapabilities.isEmpty) {
                      return const Center(
                        child: Text('No capabilities available.'),
                      );
                    }

                    // Group capabilities
                    final groups = <String, List<String>>{};
                    for (final cap in allCapabilities) {
                      final meta = catalogMeta?[cap];
                      final groupName =
                          meta?.group ?? CapabilityDictionary.getGroup(cap);
                      groups.putIfAbsent(groupName, () => []).add(cap);
                    }

                    // Flatten into a list of headers and capability IDs
                    final items = <String>[];
                    final sortedGroups = groups.keys.toList()..sort();
                    for (final g in sortedGroups) {
                      items.add('__HEADER__$g');
                      items.addAll(groups[g]!);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];

                        if (item.startsWith('__HEADER__')) {
                          final groupName = item.substring(10);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              groupName.toUpperCase(),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          );
                        }

                        final cap = item;
                        final meta = catalogMeta?[cap];
                        final isAssigned = assigned.contains(cap);

                        // Implicit admin:access grant via domain capability intersection.
                        // If this checkbox is for admin:access AND the role has other admin-domain
                        // caps (but not admin:access directly), show it as implicitly granted.
                        final isImplicitlyGranted =
                            cap == AppCapabilities.adminAccess &&
                            !isAssigned &&
                            assigned.any(
                              (c) => AppCapabilities.adminDomainCapabilities
                                  .contains(c),
                            );

                        // Action lock guard
                        final isSelfLock =
                            role == 'admin' &&
                            cap == AppCapabilities.adminAccess;
                        final isEnabled =
                            canManage &&
                            mutatingCapability == null &&
                            !isSelfLock &&
                            !isImplicitlyGranted;

                        final titleText =
                            meta?.label ?? CapabilityDictionary.getLabel(cap);
                        final subtitleText = isSelfLock
                            ? 'Cannot revoke your own admin access'
                            : isImplicitlyGranted
                            ? 'Implicitly Granted via assigned capabilities'
                            : (meta?.description ??
                                  CapabilityDictionary.getDescription(cap));

                        return CheckboxListTile(
                          key: ValueKey(cap),
                          value: isAssigned || isImplicitlyGranted,
                          enabled: isEnabled,
                          title: Row(
                            children: [
                              Expanded(child: Text(titleText)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cap,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(
                              color: isSelfLock
                                  ? Theme.of(context).colorScheme.error
                                  : (isAssigned
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant),
                            ),
                          ),
                          secondary: mutatingCapability == cap
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onChanged: isEnabled
                              ? (_) => onToggle(
                                  capability: cap,
                                  currentlyAssigned: isAssigned,
                                )
                              : null,
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
