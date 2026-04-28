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
}
