import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/services/sync_engine.dart';
import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/submission_dao.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../auth/manager/auth_manager.dart';
import '../../stores/manager/store_manager.dart';
import '../../../_shared/database/dao/program_outbox_dao.dart';
import '../../audit/manager/history_manager.dart';
import '../../action_plans/manager/action_plan_manager.dart';
import '../../programs/model/pending_assignment_vm.dart';
import '../../programs/services/program_api_service.dart';
import 'dashboard_queries.dart';
import '../../../_shared/constants/user_persona.dart';

final _di = GetIt.instance;

// ────────────────────────────────────────────────────────────────
// Sealed state hierarchy — replaces the generic DashboardStats class.
// Each role variant only exposes data relevant to that role.
// ────────────────────────────────────────────────────────────────

sealed class DashboardState {}

/// Initial / in-progress loading state.
class DashboardLoading extends DashboardState {}

/// Error state indicating data failed to load.
class DashboardErrorState extends DashboardState {
  final String message;
  DashboardErrorState(this.message);
}

/// State for Auditor role.
class AuditorDashboardState extends DashboardState {
  final int draftCount;
  final int openActionPlans;
  final double myAvgScore;
  final DateTime? nearestDeadline;
  final List<SubmissionDto> recentSubmissions;

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
  final String? storeId;
  final String? storeName;
  final int openActionPlans;
  final int overdueActionPlans;
  final double storeAvgScore;
  final DateTime? nearestDeadline;
  final List<SubmissionDto> recentSubmissions;
  final List<AreaCampaignProgressDto> areaCampaigns;

  ManagerDashboardState({
    required this.storeId,
    this.storeName,
    required this.openActionPlans,
    required this.overdueActionPlans,
    required this.storeAvgScore,
    this.nearestDeadline,
    required this.recentSubmissions,
    this.areaCampaigns = const [],
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
  final List<SubmissionDto> recentSubmissions;

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

  /// Watches pending program assignments and maps them to a UI-safe VM.
  ///
  /// Returns `null` when there are no pending assignments (widget hides itself).
  /// The [ProgramOutboxDao] is resolved lazily from GetIt so that tests that
  /// do not exercise this method are unaffected.
  Stream<List<PendingAssignmentVm>?> watchActionRequired([
    ProgramOutboxDao? programOutboxDao,
  ]) {
    final dao = programOutboxDao ?? _di<ProgramOutboxDao>();
    return dao.watchPendingAssignments().map((assignments) {
      if (assignments.isEmpty) return null;
      return assignments
          .map((a) => PendingAssignmentVm(id: a.id, title: a.programTitle))
          .toList();
    });
  }

  DashboardState _state = DashboardLoading();
  DashboardState get dashboardState => _state;

  bool get isLoading => _state is DashboardLoading;
  bool _isSyncingStores = false;

  // ---------- Void Audit (admin-only) ----------
  Future<void> voidAudit(String submissionId, String reason) async {
    await _di<SubmissionApiService>().voidSubmission(submissionId, reason);
    // Reload to reflect the voided audit in the Dashboard feed.
    await loadStats();
  }

  /// Load dashboard stats from local Drift cache, branching on role.
  Future<void> loadStats({bool showLoading = true}) async {
    if (showLoading) {
      _state = DashboardLoading();
      notifyListeners();
    }

    try {
      final persona = UserPersona.fromRole(_auth.currentUser?.role);
      final queries = DashboardQueries(_db);

      if (showLoading && _di.isRegistered<SyncEngine>()) {
        final totalCount = await queries.getTotalAuditCount();
        if (totalCount == 0) {
          // Empty cache (likely fresh login) — await the sync before loading
          await _di<SyncEngine>().requestSync();
          await Future.wait([
            if (_di.isRegistered<HistoryManager>())
              _di<HistoryManager>().loadHistory(),
            if (_di.isRegistered<ActionPlanManager>())
              _di<ActionPlanManager>().loadActionPlans(),
          ]);
        } else {
          // Cache has data — sync in background and quietly reload when done
          unawaited(() async {
            try {
              await _di<SyncEngine>().requestSync();
              await Future.wait([
                if (_di.isRegistered<HistoryManager>())
                  _di<HistoryManager>().loadHistory(),
                if (_di.isRegistered<ActionPlanManager>())
                  _di<ActionPlanManager>().loadActionPlans(),
              ]);
            } finally {
              loadStats(showLoading: false);
            }
          }());
        }
      }

      switch (persona) {
        case UserPersona.auditor:
          _state = await _loadAuditorState(queries);
        case UserPersona.storeManager:
        case UserPersona.areaManager:
          _state = await _loadManagerState(queries, persona);
        case UserPersona.admin:
          _state = await _loadAdminState(queries);
      }
    } catch (_) {
      // On any error (DB not ready, cache empty), fall back to error state
      // so the UI shows the error placeholder with a retry button rather than crashing or infinite loading.
      _state = DashboardErrorState(
        'Failed to load dashboard data. Please try again.',
      );
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
    final recent = await _getMergedRecentSubmissions(queries, limit: 10);

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
    UserPersona persona,
  ) async {
    // Get storeId from the cached store profile.
    // Store managers have exactly one store in the local cache.
    final stores = await (_db.select(_db.cachedStores)..limit(1)).get();

    if (stores.isEmpty) {
      // IA Overhaul: Resilient Manager View
      // If store sync is pending, pull personal (Auditor-like) data but wrap in Manager UI.
      // Kickstart store sync so it doesn't get stuck in "Syncing..." forever.
      if (!_isSyncingStores && _di.isRegistered<StoreManager>()) {
        _isSyncingStores = true;
        _di<StoreManager>().loadStores().whenComplete(() {
          _isSyncingStores = false;
          // Refresh dashboard if store was successfully fetched
          if (_di<StoreManager>().stores.value.isNotEmpty) {
            loadStats();
          }
        }).ignore();
      }

      final results = await Future.wait([
        queries.getMyOpenApCount(), // Personal open APs
        queries.getGlobalOverdueApCount(), // All overdue APs in scope
        queries.getMyAvgScore(), // Personal avg score
      ]);

      final deadline = await queries.getNearestDeadline();
      final recent = await _getMergedRecentSubmissions(queries, limit: 10);

      List<AreaCampaignProgressDto> campaigns = const [];
      if (persona == UserPersona.areaManager &&
          _di.isRegistered<ProgramApiService>()) {
        try {
          campaigns = await _di<ProgramApiService>().getAreaCampaignProgress();
        } catch (_) {
          // If it fails, fallback to empty so the rest of the dashboard loads
        }
      }

      return ManagerDashboardState(
        storeId: null,
        storeName: 'Syncing...',
        openActionPlans: results[0] as int,
        overdueActionPlans: results[1] as int,
        storeAvgScore: results[2] as double,
        nearestDeadline: deadline,
        recentSubmissions: recent,
        areaCampaigns: campaigns,
      );
    }

    final store = stores.first;
    final storeId = store.id;

    final results = await Future.wait([
      persona == UserPersona.areaManager
          ? queries.getMyOpenApCount()
          : queries.getOpenApCountForStore(storeId),
      persona == UserPersona.areaManager
          ? queries.getGlobalOverdueApCount()
          : queries.getOverdueApCountForStore(storeId),
      persona == UserPersona.areaManager
          ? queries.getMyAvgScore()
          : queries.getAvgScoreForStore(storeId),
    ]);

    final deadline = await queries.getNearestDeadline();
    final recent = await _getMergedRecentSubmissions(queries, limit: 10);

    List<AreaCampaignProgressDto> campaigns = const [];
    if (persona == UserPersona.areaManager &&
        _di.isRegistered<ProgramApiService>()) {
      try {
        campaigns = await _di<ProgramApiService>().getAreaCampaignProgress();
      } catch (_) {
        // If it fails, fallback to empty so the rest of the dashboard loads
      }
    }

    return ManagerDashboardState(
      storeId: storeId,
      storeName: store.name,
      openActionPlans: results[0] as int,
      overdueActionPlans: results[1] as int,
      storeAvgScore: results[2] as double,
      nearestDeadline: deadline,
      recentSubmissions: recent,
      areaCampaigns: campaigns,
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

    final recent = await _getMergedRecentSubmissions(queries, limit: 10);

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

  Future<List<SubmissionDto>> _getMergedRecentSubmissions(
    DashboardQueries queries, {
    int limit = 10,
  }) async {
    final rawRecent = await queries.getRecentSubmissions(limit: limit);
    final recent = rawRecent.map(SubmissionDao.rowToDto).toList();

    if (_di.isRegistered<HistoryManager>()) {
      final hydrated = await _di<HistoryManager>().applyLocalOverrides(recent);
      if (hydrated.length > limit) {
        return hydrated.sublist(0, limit);
      }
      return hydrated;
    }

    return recent;
  }
}
