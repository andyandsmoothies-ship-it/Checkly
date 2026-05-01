import 'pending_submission.dart';
import 'delta_pull_result.dart';
import 'pending_submission_risk.dart';

abstract class SyncApi {
  /// Push a single pending submission to the server.
  Future<void> pushSubmission(PendingSubmission submission);

  /// Pull delta updates from server since [since].
  Future<DeltaPullResult> pullDeltas(DateTime? since);

  /// Pull global risks delta from server since [since].
  Future<List<dynamic>> pullGlobalRisks(DateTime? since);

  /// Push a pending submission risk trigger to the server.
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk);

  /// Pull all active program assignments for the calling SM.
  /// Returns a raw JSON list matching AssignmentSummaryDto.
  Future<List<dynamic>> pullProgramAssignments();

  /// Push evidence items for a specific program assignment.
  /// [assignmentId]: server UUID of the ProgramAssignment.
  /// [evidenceItems]: list of {criteriaId, value, photoUrl?} maps.
  Future<void> pushProgramEvidence(
    String assignmentId,
    List<Map<String, dynamic>> evidenceItems,
  );

  /// Push a program evidence photo via multipart/form-data.
  Future<void> pushProgramPhoto(String photoLocalKey, String filePath);
}

