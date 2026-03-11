/// Sync engine state machine states.
enum SyncState {
  /// Engine is idle — no sync in progress.
  idle,

  /// A sync cycle is currently running.
  syncing,

  /// Last sync cycle encountered an error.
  error,

  /// Device is offline — sync is paused.
  offline,
}
