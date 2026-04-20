import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../manager/role_manager.dart';
import '../widgets/offline_lock_view.dart';
import '../widgets/online_role_list.dart';

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
          if (!isOnline) return const OfflineLockView();
          return OnlineRoleList(manager: _manager);
        },
      ),
    );
  }
}
