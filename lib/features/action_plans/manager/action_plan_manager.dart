import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/action_plan_outbox_dao.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../model/action_plan_dto.dart';

// ============================================================
// Interfaces
// ============================================================

/// Abstract API for action plan operations.
abstract class ActionPlanApi {
  /// Update an action plan with the given field changes.
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  );
}

/// Provides the current user's role for client-side role guards.
abstract class UserRoleProvider {
  String get role;
}

// ============================================================
// Exceptions
// ============================================================

/// Thrown when a user attempts an action their role doesn't permit.
class RoleGuardException implements Exception {
  final String message;
  const RoleGuardException(this.message);

  @override
  String toString() => 'RoleGuardException: $message';
}

/// Thrown when a state transition is invalid (e.g. from terminal state).
class InvalidTransitionException implements Exception {
  final String message;
  const InvalidTransitionException(this.message);

  @override
  String toString() => 'InvalidTransitionException: $message';
}

// ============================================================
// ActionPlanManager — role-guarded state machine + list loading
// ============================================================

final _di = GetIt.instance;

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

  ActionPlanManager({
    required ActionPlanApi api,
    required UserRoleProvider userRole,
    required ConnectivityService connectivity,
    required ActionPlanOutboxDao outboxDao,
  }) : _api = api,
       _userRole = userRole,
       _connectivity = connectivity,
       _outboxDao = outboxDao;

  // ---------- List state ----------
  final actionPlans = ValueNotifier<List<ActionPlanDto>>([]);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? error;

  /// Load action plans from local Drift cache.
  Future<void> loadActionPlans() async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      final db = _di<DatabaseService>().db;
      final rows =
          await (db.select(db.cachedActionPlans)..limit(
                500,
              )) // Bounded to 500 for mobile performance safety (Gotcha #14)
              .get();

      actionPlans.value = rows
          .map(
            (row) => ActionPlanDto(
              id: row.id,
              status: row.status,
              criteriaLabel: row.criteriaLabel,
              groupTitle: row.groupTitle,
              storeName: row.storeName,
              storeManagerName: row.storeManagerName,
              rootCause: row.rootCause,
              correctionPlan: row.correctionPlan,
              evidencePhotoUrl: row.evidencePhotoUrl,
              evidenceNote: row.evidenceNote,
              closedAt: row.closedAt,
              verifierName: row.verifierName,
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
    required String evidenceNote,
  }) async {
    _assertNotTerminal(plan);
    _assertRole(['store_manager'], 'submit evidence');
    _assertStatus(plan, 'open', 'pending_verify');

    if (!_connectivity.isOnline) {
      // --- Offline path: queue and optimistic update ---
      const uuid = Uuid();
      await _outboxDao.enqueue(
        PendingActionPlanUpdatesCompanion(
          id: Value(uuid.v4()),
          actionPlanId: Value(plan.id),
          correctionPlan: Value(correctionPlan),
          evidenceNote: Value(evidenceNote),
          createdAt: Value(DateTime.now().toUtc()),
        ),
      );

      // Build the optimistic DTO so the UI transitions instantly
      final optimistic = ActionPlanDto(
        id: plan.id,
        status: 'pending_verify',
        criteriaLabel: plan.criteriaLabel,
        groupTitle: plan.groupTitle,
        storeName: plan.storeName,
        storeManagerName: plan.storeManagerName,
        rootCause: plan.rootCause,
        correctionPlan: correctionPlan,
        evidencePhotoUrl: plan.evidencePhotoUrl,
        evidenceNote: evidenceNote,
        closedAt: plan.closedAt,
        verifierName: plan.verifierName,
        deadline: plan.deadline,
        createdAt: plan.createdAt,
        updatedAt: DateTime.now(),
      );

      // Patch in-memory list so the UI reflects the change without a DB reload
      final updated = actionPlans.value.map(
        (p) => p.id == plan.id ? optimistic : p,
      ).toList();
      actionPlans.value = updated;

      return optimistic;
    }

    // --- Online path: direct API call (original behavior) ---
    final result = await _api.updateActionPlan(plan.id, {
      'status': 'pending_verify',
      'correctionPlan': correctionPlan,
      'evidenceNote': evidenceNote,
    });

    // Patch in-memory list with the server response
    final updated = actionPlans.value.map(
      (p) => p.id == plan.id ? result : p,
    ).toList();
    actionPlans.value = updated;

    return result;
  }

  /// Auditor/Admin closes a plan after verifying evidence.
  ///
  /// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
  Future<ActionPlanDto> closePlan(
    ActionPlanDto plan, {
    required String verifierName,
  }) async {
    _assertNotTerminal(plan);
    _assertRole(['auditor', 'admin'], 'close plan');
    _assertStatus(plan, 'pending_verify', 'closed');

    return _api.updateActionPlan(plan.id, {
      'status': 'closed',
      'verifierName': verifierName,
    });
  }

  /// Auditor/Admin rejects evidence → status returns to `open`.
  ///
  /// Guards: role must be `auditor` or `admin`, status must be `pending_verify`.
  Future<ActionPlanDto> rejectEvidence(ActionPlanDto plan) async {
    _assertNotTerminal(plan);
    _assertRole(['auditor', 'admin'], 'reject evidence');
    _assertStatus(plan, 'pending_verify', 'open');

    return _api.updateActionPlan(plan.id, {
      'status': 'open',
      'evidencePhotoUrl': null,
      'evidenceNote': null,
    });
  }

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

  // ---------- Guards ----------

  void _assertNotTerminal(ActionPlanDto plan) {
    if (plan.status == 'closed') {
      throw const InvalidTransitionException(
        'Cannot transition from closed state',
      );
    }
  }

  void _assertRole(List<String> allowedRoles, String action) {
    if (!allowedRoles.contains(_userRole.role)) {
      throw RoleGuardException('Role "${_userRole.role}" cannot $action');
    }
  }

  void _assertStatus(
    ActionPlanDto plan,
    String requiredStatus,
    String targetStatus,
  ) {
    if (plan.status != requiredStatus) {
      throw InvalidTransitionException(
        'Cannot transition from "${plan.status}" to "$targetStatus"',
      );
    }
  }
}
