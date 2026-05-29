import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/constants/app_roles.dart';
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
    final theme = Theme.of(context);

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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];

                        if (item.startsWith('__HEADER__')) {
                          final groupName = item.substring(10);
                          return Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    groupName.toUpperCase(),
                                    style: AppFonts.displayStyle(
                                      fontSize:
                                          theme.textTheme.labelSmall?.fontSize,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                      letterSpacing: 3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                            role == AppRoles.admin &&
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

                        return StrokeCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.zero,
                          child: CheckboxListTile(
                            key: ValueKey(cap),
                            value: isAssigned || isImplicitlyGranted,
                            enabled: isEnabled,
                            activeColor: AppColors.featherGreen,
                            checkboxShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    titleText,
                                    style: AppFonts.displayStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          theme.textTheme.bodyMedium?.fontSize,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cap,
                                    style: AppFonts.displayStyle(
                                      fontSize:
                                          theme.textTheme.labelSmall?.fontSize,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: AppFonts.displayStyle(
                                fontSize: theme.textTheme.bodySmall?.fontSize,
                                color: isSelfLock
                                    ? theme.colorScheme.error
                                    : (isAssigned
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant),
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
