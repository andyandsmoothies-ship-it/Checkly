import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/dao/action_plan_outbox_dao.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../../../_shared/services/user_role_provider.dart';
import '../domain/action_plan.dart';
import '../model/action_plan_dto.dart';
import '../model/stale_conflict.dart';
import 'action_plan_api.dart';
export 'action_plan_api.dart';

part 'action_plan_manager_transitions.dart';

// ============================================================
// ActionPlanManager — role-guarded state machine + list loading
// ============================================================

/// Manages action plan lifecycle with client-side role guards.
///
/// The backend has NO role validation — it accepts any status from any user.
/// This manager enforces the state machine rules:
///
/// | Status          | Allowed Transitions    | Who Can Act         |
/// |-----------------|----------------------:|---------------------|
/// | `open`          | → `pending_verify`    | `store_manager`     |
/// | `pending_verify`| → `closed`, → `open`  | `auditor`, `admin`  |
/// | `closed`        | ∅ (terminal)          | Nobody              |
class ActionPlanManager extends ChangeNotifier {
  final ActionPlanApi _api;
  final UserRoleProvider _userRole;
  final ConnectivityService _connectivity;
  final ActionPlanOutboxDao _outboxDao;

  /// Injected database — required for [loadActionPlans]. Optional to allow
  /// state-machine-only test construction (S1–S8 never call loadActionPlans).
  final AppDatabase? _db;

  ActionPlanManager({
    required ActionPlanApi api,
    required UserRoleProvider userRole,
    required ConnectivityService connectivity,
    required ActionPlanOutboxDao outboxDao,
    AppDatabase? db,
  }) : _api = api,
       _userRole = userRole,
       _connectivity = connectivity,
       _outboxDao = outboxDao,
       _db = db;

  // ---------- Offline Conflict Recovery ----------
  /// Get the stale offline conflict for this plan, if it exists.
  /// Returns a [StaleConflict] DTO so callers do not need a DB import.
  Future<StaleConflict?> getStaleConflict(String planId) async {
    final result = await _outboxDao.getStaleConflictForPlan(planId);
    if (result == null) return null;
    return StaleConflict(
      id: result.id,
      correctionPlan: result.correctionPlan,
      evidenceNote: result.evidenceNote,
    );
  }

  /// Dismiss the stale conflict by removing it from the outbox.
  Future<void> dismissStaleConflict(String id) {
    return _outboxDao.remove(id);
  }

  // ---------- List state ----------
  final actionPlans = ValueNotifier<List<ActionPlanDto>>([]);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? error;

  /// Fetch a single action plan by ID and merge it into [actionPlans].
  ///
  /// Used by [ActionPlanDetailPage] when the plan is not already in the
  /// local cache — avoids reloading the entire list just to show one plan.
  ///
  /// Returns `true` if the plan was found and added, `false` if not found
  /// (server returned 404 or the plan is not accessible to this user).
  Future<bool> loadSinglePlan(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final plan = await _api.fetchActionPlan(id);
      if (plan == null) return false;
      // Merge: replace existing entry if present, otherwise append.
      final current = List<ActionPlanDto>.from(actionPlans.value);
      final idx = current.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        current[idx] = plan;
      } else {
        current.add(plan);
      }
      actionPlans.value = current;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load action plans — network-first with local cache fallback.
  ///
  /// **Online path:** Calls `fetchActionPlans()`, upserts all results into
  /// `cachedActionPlans` (replace-on-conflict), then populates `actionPlans.value`
  /// from the returned list directly (no extra DB round-trip needed).
  ///
  /// **Offline / error path:** Reads from the local `cachedActionPlans` table,
  /// bounded to 500 rows for mobile performance (Gotcha #14).
  Future<void> loadActionPlans() async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Promote nullable _db to non-null once (S1-S8 tests never call this method).
      final db = _db!;

      if (_connectivity.isOnline) {
        try {
          // --- Online path: fetch → upsert → expose ---
          final remote = await _api.fetchActionPlans();

          // Upsert: insert-or-replace all remote plans into local cache.
          await db.batch((batch) {
            batch.insertAll(
              db.cachedActionPlans,
              remote.map(
                (plan) => CachedActionPlansCompanion.insert(
                  id: plan.id,
                  submissionId: Value(plan.submissionId),
                  criteriaLabel: plan.criteriaLabel,
                  groupTitle: plan.groupTitle,
                  status: Value(plan.status),
                  storeName: Value(plan.storeName),
                  storeId: Value(plan.storeId),
                  storeManagerName: Value(plan.storeManagerName),
                  rootCause: Value(plan.rootCause),
                  correctionPlan: Value(plan.correctionPlan),
                  evidencePhotoUrl: Value(plan.evidencePhotoUrl),
                  evidenceNote: Value(plan.evidenceNote),
                  closedAt: Value(plan.closedAt),
                  verifierName: Value(plan.verifierName),
                  evidenceSubmittedAt: Value(plan.evidenceSubmittedAt),
                  evidenceSubmittedByName: Value(plan.evidenceSubmittedByName),
                  deadline: Value(plan.deadline),
                  createdAt: plan.createdAt,
                  updatedAt: plan.updatedAt,
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
          });

          actionPlans.value = remote;
          return; // Skip the offline cache-read path
        } catch (_) {
          // Network or parse failure — fall through to cache fallback below.
          // Errors are swallowed to ensure graceful degradation (AP_PULL_03).
        }
      }

      // --- Offline / error fallback: read local cache ---
      final rows =
          await (db.select(db.cachedActionPlans)..limit(
                500,
              )) // Bounded to 500 for mobile performance safety (Gotcha #14)
              .get();

      actionPlans.value = rows
          .map(
            (row) => ActionPlanDto(
              id: row.id,
              submissionId: row.submissionId,
              status: row.status,
              criteriaLabel: row.criteriaLabel,
              groupTitle: row.groupTitle,
              storeName: row.storeName,
              storeId: row.storeId,
              storeManagerName: row.storeManagerName,
              rootCause: row.rootCause,
              correctionPlan: row.correctionPlan,
              evidencePhotoUrl: row.evidencePhotoUrl,
              evidenceNote: row.evidenceNote,
              closedAt: row.closedAt,
              verifierName: row.verifierName,
              evidenceSubmittedAt: row.evidenceSubmittedAt,
              evidenceSubmittedByName: row.evidenceSubmittedByName,
              deadline: row.deadline,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList();
    } catch (_) {
      error = 'Failed to load action plans';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------- State machine transitions ----------

  /// SM submits correction evidence → status changes to `pending_verify`.
  ///
  /// Guards: role must be `store_manager`, status must be `open`.
  ///
  /// **Offline-first (P1 UX Fix):** If the device is offline, the payload is
  /// written to `PendingActionPlanUpdates` (SQLite queue) and the in-memory
  /// cache is updated optimistically so the UI reflects the change immediately.
  /// When connectivity is restored, `SyncEngine` drains the queue.
  Future<ActionPlanDto> submitEvidence(
    ActionPlanDto plan, {
    required String correctionPlan,
    required String currentUserName,
    String? evidenceNote,
    String? photoPath,
  }) async => _submitEvidenceLogic(
    this,
    plan,
    correctionPlan: correctionPlan,
    currentUserName: currentUserName,
    evidenceNote: evidenceNote,
    photoPath: photoPath,
  );

  /// Auditor/Admin closes a plan after verifying evidence.
  ///
  /// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
  Future<ActionPlanDto> closePlan(
    ActionPlanDto plan, {
    required String verifierName,
  }) async => _closePlanLogic(this, plan, verifierName: verifierName);

  /// Auditor/Admin rejects evidence → status returns to `open`.
  ///
  /// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
  Future<ActionPlanDto> rejectEvidence(ActionPlanDto plan) async =>
      _rejectEvidenceLogic(this, plan);

  // ---------- Static utilities ----------

  /// Check if a plan is overdue: open + past deadline.
  static bool isOverdue(ActionPlanDto plan, {required DateTime now}) {
    if (plan.status != 'open') return false;
    if (plan.deadline == null) return false;
    return plan.deadline!.isBefore(now);
  }

  /// Returns the list of valid target statuses for a given current status.
  static List<String> allowedTransitions(String status) {
    switch (status) {
      case 'open':
        return ['pending_verify'];
      case 'pending_verify':
        return ['closed', 'open'];
      case 'closed':
        return [];
      default:
        return [];
    }
  }

}
