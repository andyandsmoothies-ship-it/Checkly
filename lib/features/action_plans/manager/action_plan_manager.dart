import '../model/action_plan_dto.dart';

// ============================================================
// Interfaces
// ============================================================

/// Abstract API for action plan updates.
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
// ActionPlanManager — role-guarded state machine
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
class ActionPlanManager {
  final ActionPlanApi _api;
  final UserRoleProvider _userRole;

  ActionPlanManager({
    required ActionPlanApi api,
    required UserRoleProvider userRole,
  }) : _api = api,
       _userRole = userRole;

  // ---------- State machine transitions ----------

  /// SM submits correction evidence → status changes to `pending_verify`.
  ///
  /// Guards: role must be `store_manager`, status must be `open`.
  Future<ActionPlanDto> submitEvidence(
    ActionPlanDto plan, {
    required String correctionPlan,
    required String evidenceNote,
  }) async {
    _assertNotTerminal(plan);
    _assertRole(['store_manager'], 'submit evidence');
    _assertStatus(plan, 'open', 'pending_verify');

    return _api.updateActionPlan(plan.id, {
      'status': 'pending_verify',
      'correctionPlan': correctionPlan,
      'evidenceNote': evidenceNote,
    });
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
