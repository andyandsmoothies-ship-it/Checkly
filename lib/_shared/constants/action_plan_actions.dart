// Action key constants for Action Plan entity-level gating.
// These strings mirror the backend Action Plan allowedActions contract.
// Use these constants instead of raw strings.

/// Action keys returned in ActionPlanDto.allowedActions by the server.
abstract final class ActionPlanActions {
  static const String view = 'view';
  static const String submitEvidence = 'submit_evidence';
  static const String verifyClose = 'verify_close';
  static const String rejectEvidence = 'reject_evidence';

  /// Local-only actions for offline-created pending records.
  static const String edit = 'edit';
  static const String delete = 'delete';
}
