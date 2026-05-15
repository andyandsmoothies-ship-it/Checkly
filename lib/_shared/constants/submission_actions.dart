// Action key constants for entity-level capability gating.
// These strings mirror C# SubmissionActions constants in
// server/Features/Submissions/SubmissionActions.cs.
// NEVER use raw strings — always use these constants.

/// Action keys returned in [SubmissionDto.allowedActions] by the server.
/// Used by [ActionGuard] to determine which actions are available on a
/// specific submission based on both the user's role AND the entity status.
abstract final class SubmissionActions {
  /// Always included. User can view the submission.
  static const String view = 'view';

  /// User can edit a draft or scheduled submission.
  static const String edit = 'edit';

  /// User can finalize a completed submission.
  static const String finalize = 'finalize';

  /// User can void an active submission.
  /// Named [voidAction] to avoid collision with the Dart [void] keyword.
  static const String voidAction = 'void';
}
