/// Flutter-side mirror of server/Features/Programs/AssignmentStatus.cs
/// NEVER change these values — they are stored as-is in the database.
abstract final class AssignmentStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String submitted = 'submitted';
  static const String needsRevision = 'needs_revision';
  static const String verified = 'verified';
  static const String overdue = 'overdue';
}
