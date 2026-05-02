import '../model/action_plan_dto.dart';
import '../models/add_comment_request.dart';
import '../models/comment_dto.dart';

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

  /// Upload a photo for an action plan (via the underlying submission).
  Future<String> uploadPhoto(String submissionId, String filePath) =>
      throw UnimplementedError('uploadPhoto() not implemented');

  /// Fetch all action plans from the server for the authenticated user.
  /// Concrete adapters override this. Default throws to prevent silent misuse.
  Future<List<ActionPlanDto>> fetchActionPlans() =>
      throw UnimplementedError('fetchActionPlans() not implemented');

  /// Add a comment to an action plan.
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) => throw UnimplementedError('addComment() not implemented');

  /// Fetch a single action plan by ID from the server.
  /// Returns null if the server returns 404 (not found or no access).
  Future<ActionPlanDto?> fetchActionPlan(String id) =>
      throw UnimplementedError('fetchActionPlan() not implemented');
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

/// Thrown when the backend rejects an action plan mutation because the plan is already closed.
/// Used by [ActionPlanApiAdapter] to signal a terminal-state conflict (HTTP 409
/// with code=action_plan_already_closed). The SyncEngine safe-drains this entry.
class ActionPlanAlreadyClosedException implements Exception {
  const ActionPlanAlreadyClosedException();

  @override
  String toString() =>
      'ActionPlanAlreadyClosedException: The action plan is already in a terminal state.';
}
