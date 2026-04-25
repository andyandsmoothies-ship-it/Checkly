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
import '../../../_shared/database/dao/outbox_dao.dart';
import '../../audit/manager/history_manager.dart';
import '../../action_plans/manager/action_plan_manager.dart';
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
      final role = _auth.currentUser?.role ?? 'admin';
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
    String role,
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
        Future.value(0), // No "store" overdue yet
        queries.getMyAvgScore(), // Personal avg score
      ]);

      final deadline = await queries.getNearestDeadline();
      final recent = await _getMergedRecentSubmissions(queries, limit: 10);

      return ManagerDashboardState(
        storeId: null,
        storeName: 'Syncing...',
        openActionPlans: results[0] as int,
        overdueActionPlans: results[1] as int,
        storeAvgScore: results[2] as double,
        nearestDeadline: deadline,
        recentSubmissions: recent,
      );
    }

    final store = stores.first;
    final storeId = store.id;

    final results = await Future.wait([
      queries.getOpenApCountForStore(storeId),
      queries.getOverdueApCountForStore(storeId),
      queries.getAvgScoreForStore(storeId),
    ]);

    final deadline = await queries.getNearestDeadline();
    final recent = await _getMergedRecentSubmissions(queries, limit: 10);

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

    final outboxDao = OutboxDao(_db);
    final pendingRows = await outboxDao.getAllPending();
    if (pendingRows.isNotEmpty) {
      for (final p in pendingRows) {
        if (p.targetSubmissionId != null) {
          recent.removeWhere((s) => s.id == p.targetSubmissionId);
        }
        String? tTitle;
        String? sName;
        try {
          final tRow = await (_db.select(
            _db.cachedTemplates,
          )..where((t) => t.id.equals(p.templateId))).getSingleOrNull();
          if (tRow != null) tTitle = tRow.title;
          final sRow = await (_db.select(
            _db.cachedStores,
          )..where((s) => s.id.equals(p.storeId))).getSingleOrNull();
          if (sRow != null) sName = sRow.name;
        } catch (_) {}

        recent.insert(
          0,
          SubmissionDto(
            id: 'local_outbox_${p.id}',
            templateId: p.templateId,
            templateTitle: tTitle ?? 'Audit',
            storeId: p.storeId,
            storeName: sName ?? 'Unknown Store',
            status: p.syncStatus == 'pending'
                ? 'syncing'
                : (p.syncStatus == 'exhausted' ? 'failed' : 'syncing'),
            createdAt: p.createdAt,
            totalScore: p.clientScore,
          ),
        );
      }
      recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (recent.length > limit) {
        return recent.sublist(0, limit);
      }
    }
    return recent;
  }
}
