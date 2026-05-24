import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../constants/app_capabilities.dart';
import '../services/policy_manager.dart';

final _di = GetIt.instance;

/// SC-3: Auth redirect guard extracted from app_router.dart.
/// Redirects unauthenticated users to /login.
/// Redirects non-admin users away from /admin/* routes to /home.
/// Redirects non-admin users away from /templates/* mutation routes to /home.
/// Read-only /templates/:id detail pages are whitelisted for all authenticated roles.
String? authRedirect(BuildContext context, GoRouterState state) {
  final auth = _di<AuthManager>();
  final isAuthenticated = auth.authState.value == AuthState.authenticated;
  final isOnLogin = state.matchedLocation == '/login';

  if (auth.authState.value == AuthState.loading) return null;
  if (!isAuthenticated &&
      !isOnLogin &&
      state.matchedLocation != '/access-pending') {
    return '/login';
  }
  if (isAuthenticated && isOnLogin) {
    // No-role guard: users without a valid role see Access Pending
    final role = auth.currentUser?.role;
    if (role == null || role.isEmpty) return '/access-pending';
    return '/home';
  }

  // Admin capability guard: requires 'admin:access' UI-Signal capability.
  // This is the ONLY capability checked at the router prefix level.
  // Granular capability checks (e.g. admin:manage_roles) belong inside individual
  // admin pages/widgets — NOT here. Checking granulars here causes the
  // Group Policy Trap: a user with stores:write but not manage_roles gets locked out.
  // Fail-safe deny: empty capabilities → redirect to /home.
  //
  // Whitelist: /admin/approvals is also accessible to users with submissions:review
  // (Area Managers) without granting full admin:access to the entire /admin/* prefix.
  if (isAuthenticated && state.matchedLocation.startsWith('/admin')) {
    final pm = _di<PolicyManager>();
    final isApprovalRoute = state.matchedLocation == '/admin/approvals';
    final canReview = pm.can(AppCapabilities.submissionsReview);
    final hasAdminAccess = pm.can(AppCapabilities.adminAccess);

    if (isApprovalRoute && (hasAdminAccess || canReview)) {
      // Allow: user has either full admin or the specific review capability
    } else if (!isApprovalRoute && !hasAdminAccess) {
      return '/home';
    } else if (isApprovalRoute && !hasAdminAccess && !canReview) {
      return '/home';
    }
  }

  // Template mutation capability guard: requires 'templates:create' capability.
  // Default Deny: ALL /templates/* paths are mutations EXCEPT the exact read-only
  // detail path /templates/:id (exactly 3 path segments, not 'new' or 'wizard').
  if (isAuthenticated && state.matchedLocation.startsWith('/templates/')) {
    final parts = state.matchedLocation.split('/');
    // Whitelist: ['', 'templates', '<id>'] — must be exactly 3 segments
    // and the id segment cannot be a known mutation keyword.
    final isReadOnlyDetail =
        parts.length == 3 && parts[2] != 'new' && parts[2] != 'wizard';
    if (!isReadOnlyDetail &&
        !_di<PolicyManager>().can(AppCapabilities.templatesCreate)) {
      return '/home';
    }
  }

  if (isAuthenticated) {
    final pm = _di<PolicyManager>();

    if (state.matchedLocation == '/analytics/bod') {
      if (!pm.can(AppCapabilities.analyticsBod)) {
        return '/home';
      }
    } else if (state.matchedLocation.startsWith('/analytics') &&
        !pm.can(AppCapabilities.analyticsView)) {
      return '/home';
    }

    if (state.matchedLocation.startsWith('/activity') &&
        !pm.can(AppCapabilities.submissionsList)) {
      return '/home';
    }

    if (state.matchedLocation.startsWith('/programs')) {
      final parts = state.matchedLocation.split('/');
      if (parts.length == 2 && !pm.can(AppCapabilities.programsList)) {
        return '/home';
      } else if (parts.length == 3 &&
          parts[2] != 'new' &&
          !pm.can(AppCapabilities.programsExecute)) {
        return '/home';
      } else if (parts.length == 4 &&
          parts[2] == 'review' &&
          !pm.can(AppCapabilities.programsReview)) {
        return '/home';
      }
    }
  }

  // No-role guard on all app routes (except /access-pending and /login)
  if (isAuthenticated &&
      state.matchedLocation != '/access-pending' &&
      state.matchedLocation != '/login') {
    final role = auth.currentUser?.role;
    if (role == null || role.isEmpty) return '/access-pending';
  }

  return null;
}
