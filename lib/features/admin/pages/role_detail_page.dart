import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../manager/role_manager.dart';
import '../model/role_dto.dart';
import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// Shows the capability catalog for one role as a toggleable checkbox grid.
///
/// Enforces the Online-Only Mandate (ADR Option A):
/// - If offline → full-page lock screen (AT-01/02).
/// - If no `admin:manage_roles` capability → checkboxes disabled (AT-03).
/// - Tapping a checkbox fires atomic grant/revoke and reloads (AT-04).
/// - On mutation failure → SnackBar shown, local checkbox NOT toggled (AT-05).
class RoleDetailPage extends StatefulWidget {
  final String role;
  const RoleDetailPage({super.key, required this.role});

  @override
  State<RoleDetailPage> createState() => _RoleDetailPageState();
}

class _RoleDetailPageState extends State<RoleDetailPage> {
  late final RoleManager _manager;
  late final ConnectivityService _connectivity;
  late final PolicyManager _policy;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _manager = _di<RoleManager>();
    _connectivity = _di<ConnectivityService>();
    _policy = _di<PolicyManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_connectivity.isOnline) {
        _manager.loadRoles();
        _manager.loadCatalog();
      }
    });
  }

  Future<void> _toggle({
    required String capability,
    required bool currentlyAssigned,
  }) async {
    setState(() => _isMutating = true);
    try {
      if (currentlyAssigned) {
        await _manager.revokeCommand.execute({
          'role': widget.role,
          'capability': capability,
        });
      } else {
        await _manager.grantCommand.execute({
          'role': widget.role,
          'capability': capability,
        });
      }
    } catch (e) {
      // AT-05: mutation failed — do NOT toggle local state; show SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('We hit a snag processing your request. Please check your internet connection and try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} — Capabilities'),
        actions: [
          if (_isMutating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: StreamBuilder<bool>(
        stream: _connectivity.onConnectivityChanged,
        initialData: _connectivity.isOnline,
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? _connectivity.isOnline;
          // AT-02: connection drops mid-session → immediate lock screen.
          if (!isOnline) return const _OfflineDetailLockView();
          return _OnlineCapabilityGrid(
            role: widget.role,
            manager: _manager,
            isMutating: _isMutating,
            canManage: _policy.can('admin:manage_roles'),
            onToggle: _toggle,
          );
        },
      ),
    );
  }
}

class _OnlineCapabilityGrid extends StatelessWidget {
  final String role;
  final RoleManager manager;
  final bool isMutating;
  final bool canManage;
  final Future<void> Function({
    required String capability,
    required bool currentlyAssigned,
  }) onToggle;

  const _OnlineCapabilityGrid({
    required this.role,
    required this.manager,
    required this.isMutating,
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

                    final thisRole = roles?.where((r) => r.role == role).firstOrNull;
                    final assigned = thisRole?.capabilities ?? [];
                    final allCapabilities = catalog ?? assigned;

                    if (allCapabilities.isEmpty) {
                      return const Center(child: Text('No capabilities available.'));
                    }

                    // Group capabilities
                    final groups = <String, List<String>>{};
                    for (final cap in allCapabilities) {
                      final meta = catalogMeta?[cap];
                      final groupName = meta?.group ?? 'Other';
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
                        final isImplicitlyGranted = cap == AppCapabilities.adminAccess &&
                            !isAssigned &&
                            assigned.any((c) => AppCapabilities.adminDomainCapabilities.contains(c));

                        // Action lock guard
                        final isSelfLock = role == 'admin' && cap == AppCapabilities.adminAccess;
                        final isEnabled = canManage && !isMutating && !isSelfLock && !isImplicitlyGranted;

                        final titleText = meta?.label ?? cap;
                        final subtitleText = isSelfLock
                            ? 'Cannot revoke your own admin access'
                            : isImplicitlyGranted
                                ? 'Implicitly Granted via assigned capabilities'
                                : (meta?.description ?? (isAssigned ? 'Assigned' : 'Not assigned'));

                        return CheckboxListTile(
                          key: ValueKey(cap),
                          value: isAssigned || isImplicitlyGranted,
                          enabled: isEnabled,
                          title: Text(titleText),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(
                              color: isSelfLock 
                                  ? Theme.of(context).colorScheme.error
                                  : (isAssigned
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
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


/// Full-page lock shown when device goes offline mid-session (AT-02).
class _OfflineDetailLockView extends StatelessWidget {
  const _OfflineDetailLockView();

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
            'Capability changes are online-only to prevent security state drift.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
