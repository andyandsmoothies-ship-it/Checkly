import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';
import '../../auth/manager/auth_manager.dart';
import 'dashboard_queries.dart';

final _di = GetIt.instance;

// ────────────────────────────────────────────────────────────────
// Sealed state hierarchy — replaces the generic DashboardStats class.
// Each role variant only exposes data relevant to that role.
// ────────────────────────────────────────────────────────────────

sealed class DashboardState {}

/// Initial / in-progress loading state.
class DashboardLoading extends DashboardState {}

/// State for Auditor role.
class AuditorDashboardState extends DashboardState {
  final int draftCount;
  final int openActionPlans;
  final double myAvgScore;
  final DateTime? nearestDeadline;
  final List<CachedSubmission> recentSubmissions;

  AuditorDashboardState({
    required this.draftCount,
    required this.openActionPlans,
    required this.myAvgScore,
    this.nearestDeadline,
    required this.recentSubmissions,
  });
}

/// State for Store Manager and Area Manager roles.
class ManagerDashboardState extends DashboardState {
  final String storeId;
  final String? storeName;
  final int openActionPlans;
  final int overdueActionPlans;
  final double storeAvgScore;
  final DateTime? nearestDeadline;
  final List<CachedSubmission> recentSubmissions;

  ManagerDashboardState({
    required this.storeId,
    this.storeName,
    required this.openActionPlans,
    required this.overdueActionPlans,
    required this.storeAvgScore,
    this.nearestDeadline,
    required this.recentSubmissions,
  });
}

/// State for Admin role.
class AdminDashboardState extends DashboardState {
  final int totalAudits;
  final double globalAvgScore;
  final int weakStoreCount;
  final int openActionPlans;
  final int overdueActionPlans;
  final int monthlyCompleted;
  final int monthlyTotal;
  final List<CachedSubmission> recentSubmissions;

  AdminDashboardState({
    required this.totalAudits,
    required this.globalAvgScore,
    required this.weakStoreCount,
    required this.openActionPlans,
    required this.overdueActionPlans,
    required this.monthlyCompleted,
    required this.monthlyTotal,
    required this.recentSubmissions,
  });
}

// ────────────────────────────────────────────────────────────────
// DashboardManager
// ────────────────────────────────────────────────────────────────

/// Manager for the dashboard — reads stats from local Drift cache.
///
/// Branches on [AuthManager.currentUser.role] to produce a role-scoped
/// [DashboardState] variant. All DB access is via [DashboardQueries],
/// which uses Drift `count()` expressions to avoid full-table loads.
class DashboardManager extends ChangeNotifier {
  final AppDatabase _db;
  final AuthManager _auth;

  DashboardManager({AppDatabase? db, AuthManager? auth})
    : _db = db ?? _di<DatabaseService>().db,
      _auth = auth ?? _di<AuthManager>();

  DashboardState _state = DashboardLoading();
  DashboardState get dashboardState => _state;

  bool get isLoading => _state is DashboardLoading;

  /// Load dashboard stats from local Drift cache, branching on role.
  Future<void> loadStats() async {
    _state = DashboardLoading();
    notifyListeners();

    try {
      final role = _auth.currentUser?.role ?? 'admin';
      final queries = DashboardQueries(_db);

      switch (role) {
        case 'auditor':
          _state = await _loadAuditorState(queries);
        case 'store_manager':
        case 'area_manager':
          _state = await _loadManagerState(queries, role);
        default:
          // admin — also fallback for unknown roles
          _state = await _loadAdminState(queries);
      }
    } catch (_) {
      // On any error (DB not ready, cache empty), fall back to loading state
      // so the UI shows the loading placeholder rather than crashing.
      _state = DashboardLoading();
    } finally {
      notifyListeners();
    }
  }

  // ── Role-specific loaders ────────────────────────────────────────

  Future<AuditorDashboardState> _loadAuditorState(
    DashboardQueries queries,
  ) async {
    final results = await Future.wait([
      queries.getDraftCount(),
      queries.getMyOpenApCount(),
      queries.getMyAvgScore(),
    ]);

    final deadline = await queries.getNearestDeadline();
    final recent = await queries.getRecentSubmissions(limit: 10);

    return AuditorDashboardState(
      draftCount: results[0] as int,
      openActionPlans: results[1] as int,
      myAvgScore: results[2] as double,
      nearestDeadline: deadline,
      recentSubmissions: recent,
    );
  }

  Future<DashboardState> _loadManagerState(
    DashboardQueries queries,
    String role,
  ) async {
    // Get storeId from the cached store profile.
    // Store managers have exactly one store in the local cache.
    final stores = await (_db.select(_db.cachedStores)..limit(1)).get();
    if (stores.isEmpty) {
      // No store synced yet — fallback to auditor-style view
      return _loadAuditorState(queries);
    }

    final store = stores.first;
    final storeId = store.id;

    final results = await Future.wait([
      queries.getOpenApCountForStore(storeId),
      queries.getOverdueApCountForStore(storeId),
      queries.getAvgScoreForStore(storeId),
    ]);

    final deadline = await queries.getNearestDeadline();
    final recent = await queries.getRecentSubmissions(limit: 10);

    return ManagerDashboardState(
      storeId: storeId,
      storeName: store.name,
      openActionPlans: results[0] as int,
      overdueActionPlans: results[1] as int,
      storeAvgScore: results[2] as double,
      nearestDeadline: deadline,
      recentSubmissions: recent,
    );
  }

  Future<AdminDashboardState> _loadAdminState(DashboardQueries queries) async {
    final results = await Future.wait([
      queries.getTotalAuditCount(),
      queries.getGlobalAvgScore(),
      queries.getWeakStoreCount(),
      queries.getGlobalOpenApCount(),
      queries.getGlobalOverdueApCount(),
      queries.getMonthlyCompletedCount(),
      queries.getMonthlyTotal(),
    ]);

    final recent = await queries.getRecentSubmissions(limit: 10);

    return AdminDashboardState(
      totalAudits: results[0] as int,
      globalAvgScore: results[1] as double,
      weakStoreCount: results[2] as int,
      openActionPlans: results[3] as int,
      overdueActionPlans: results[4] as int,
      monthlyCompleted: results[5] as int,
      monthlyTotal: results[6] as int,
      recentSubmissions: recent,
    );
  }
}
