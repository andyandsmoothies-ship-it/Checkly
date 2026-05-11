import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';

import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../manager/role_manager.dart';
import '../widgets/offline_detail_lock_view.dart';
import '../widgets/online_capability_grid.dart';

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
  String? _mutatingCapability;

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
    setState(() => _mutatingCapability = capability);
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
    } on DioException catch (e) {
      // AT-05: mutation failed — do NOT toggle local state; show error.
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    } finally {
      if (mounted) setState(() => _mutatingCapability = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} — Capabilities'),
        actions: const [],
      ),
      body: StreamBuilder<bool>(
        stream: _connectivity.onConnectivityChanged,
        initialData: _connectivity.isOnline,
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? _connectivity.isOnline;
          // AT-02: connection drops mid-session → immediate lock screen.
          if (!isOnline) return const OfflineDetailLockView();
          return OnlineCapabilityGrid(
            role: widget.role,
            manager: _manager,
            mutatingCapability: _mutatingCapability,
            canManage: _policy.can('admin:manage_roles'),
            onToggle: _toggle,
          );
        },
      ),
    );
  }
}
