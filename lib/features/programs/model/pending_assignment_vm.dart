/// View model for pending program assignments surfaced in the Dashboard.
///
/// Decouples the UI layer from the Drift-generated [CachedProgramAssignment]
/// row type. [DashboardManager.watchActionRequired] maps the raw DAO stream
/// into this type before the widget ever sees it.
class PendingAssignmentVm {
  final String id;
  final String title;

  const PendingAssignmentVm({required this.id, required this.title});
}
