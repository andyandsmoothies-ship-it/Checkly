import 'pending_submission.dart';
import 'delta_pull_result.dart';
import 'pending_submission_risk.dart';

abstract class SyncApi {
  /// Push a single pending submission to the server.
  Future<void> pushSubmission(PendingSubmission submission);

  /// Pull delta updates from server using cursor pagination.
  Future<DeltaPullResult> pullDeltas({
    DateTime? cursorUpdatedAt,
    String? cursorId,
    String? storeId,
  });

  /// Pull global risks delta from server since [since].
  Future<List<dynamic>> pullGlobalRisks(DateTime? since);

  /// Push a pending submission risk trigger to the server.
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk);

  /// Pull all active program assignments for the calling SM.
  /// The backend is paginated, but this method aggregates all pages internally
  /// and returns a full, raw JSON list matching AssignmentSummaryDto.
  Future<List<dynamic>> pullProgramAssignments();
}
