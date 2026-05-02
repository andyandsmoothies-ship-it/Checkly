import '../../../_shared/services/sync_module.dart';
import '../../../_shared/database/dao/action_plan_outbox_dao.dart';
import '../../../_shared/database/app_database.dart';
import '../../../_shared/services/connectivity_service.dart';
import '../manager/action_plan_api.dart';

class ActionPlanSyncModule extends BaseSyncModule {
  final ActionPlanApi _api;
  final ActionPlanOutboxDao _outboxDao;
  final ConnectivityService _connectivity;

  ActionPlanSyncModule({
    required ActionPlanApi api,
    required ActionPlanOutboxDao outboxDao,
    required ConnectivityService connectivity,
    required super.scheduleRetry,
  }) : _api = api,
       _outboxDao = outboxDao,
       _connectivity = connectivity;

  @override
  int get priority => 20;

  @override
  Future<void> executePush() async {
    final pendingEvidence = await _outboxDao.getEligiblePending();

    await processQueue<PendingActionPlanUpdate>(
      pendingEvidence,
      isOnline: () => _connectivity.isOnline,
      getRetryCount: (item) => item.retryCount,
      push: (item) async {
        try {
          final submissionId = await _outboxDao.getSubmissionIdForPlan(
            item.actionPlanId,
          );
          String? photoUrl;
          if (item.photoPath != null && submissionId != null) {
            photoUrl = await _api.uploadPhoto(submissionId, item.photoPath!);
          }
          await _api.updateActionPlan(item.actionPlanId, {
            'status': 'pending_verify',
            'correctionPlan': item.correctionPlan,
            'evidenceNote': item.evidenceNote,
            'evidencePhotoUrl': photoUrl,
          });
        } on ActionPlanAlreadyClosedException {
          throw Exception('409 Conflict: ActionPlanAlreadyClosedException');
        }
      },
      onSuccess: (item) => _outboxDao.remove(item.id),
      onExhausted: (item, error) => _outboxDao.markExhausted(item.id, error),
      onRetry: (item, newRetryCount, nextRetry, error) =>
          _outboxDao.updateRetry(item.id, newRetryCount, nextRetry, error),
      isFatalError: (error) =>
          false, // All errors are transient; conflict is handled via onConflict
      onConflict: (item) => _outboxDao.markStaleConflict(item.id),
    );
  }
}
