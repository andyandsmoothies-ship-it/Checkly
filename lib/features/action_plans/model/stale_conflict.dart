/// Thin DTO representing a stale offline conflict for an action plan.
///
/// Used by [ActionPlanDetailPage] to display the [StaleConflictBanner]
/// without importing the Drift database layer into the page.
///
/// Fields mirror the 3 values the page accesses from [PendingActionPlanUpdate].
class StaleConflict {
  final String id;
  final String correctionPlan;
  final String? rootCause;
  final String evidenceNote;

  const StaleConflict({
    required this.id,
    required this.correctionPlan,
    this.rootCause,
    required this.evidenceNote,
  });
}
