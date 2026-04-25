import 'package:flutter/foundation.dart';

import '../model/role_dto.dart';
import '../services/admin_api_service.dart';

/// Simple async command wrapper used by [RoleManager].
/// Exposes [execute] to match the TDD test interface.
/// Wraps an async function that takes a Map payload.
class RoleCommand {
  final Future<void> Function(Map<String, dynamic>) _fn;
  RoleCommand(this._fn);
  Future<void> execute(Map<String, dynamic> params) => _fn(params);
}

/// Manages role and capability state for the Admin Role Management UI.
///
/// Strictly online-only — no offline cache (Option A ADR mandate).
/// - [roles]: current list of all roles from server, null until first load.
/// - [catalog]: capability catalog from server, null until first load.
/// - [isLoading]: true while any fetch is in flight.
/// - [error]: last error message, null when healthy.
/// - [grantCommand]: fires grantCapability then reloads.
/// - [revokeCommand]: fires revokeCapability then reloads.
class RoleManager extends ChangeNotifier {
  final AdminApiService _api;

  RoleManager({required AdminApiService adminApiService})
    : _api = adminApiService {
    grantCommand = RoleCommand(_grant);
    revokeCommand = RoleCommand(_revoke);
  }

  final roles = ValueNotifier<List<RoleDto>?>(null);
  final catalog = ValueNotifier<List<String>?>(null);
  final catalogMeta = ValueNotifier<Map<String, CapabilityMeta>?>(null);
  final isLoading = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);

  late final RoleCommand grantCommand;
  late final RoleCommand revokeCommand;

  /// Fetches all roles and their capabilities from the server.
  /// Sets [isLoading] true for the duration, clears [error] on success.
  Future<void> loadRoles() async {
    isLoading.value = true;
    error.value = null;
    try {
      roles.value = await _api.getRoles();
    } catch (e) {
      error.value = e.toString();
      roles.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches the static capability catalog from the server.
  Future<void> loadCatalog() async {
    try {
      final (caps, meta) = await _api.getCapabilityCatalogFull();
      catalog.value = caps;
      catalogMeta.value = meta;
    } catch (_) {
      // Non-fatal — catalog is supplementary to roles list.
    }
  }

  Future<void> _grant(Map<String, dynamic> params) async {
    final role = params['role'] as String;
    final capability = params['capability'] as String;
    await _api.grantCapability(role: role, capability: capability);
    await loadRoles();
  }

  Future<void> _revoke(Map<String, dynamic> params) async {
    final role = params['role'] as String;
    final capability = params['capability'] as String;
    await _api.revokeCapability(role: role, capability: capability);
    await loadRoles();
  }

  @override
  void dispose() {
    roles.dispose();
    catalog.dispose();
    catalogMeta.dispose();
    isLoading.dispose();
    error.dispose();
    super.dispose();
  }
}
