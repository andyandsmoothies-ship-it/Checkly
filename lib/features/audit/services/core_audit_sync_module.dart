import 'dart:convert';
import 'package:drift/drift.dart' show Value;

import '../../../_shared/services/sync_module.dart';
import '../../../_shared/services/sync_api.dart';
import '../../../_shared/database/dao/outbox_dao.dart';
import '../../../_shared/database/dao/global_risk_dao.dart';
import '../../../_shared/database/dao/submission_risk_outbox_dao.dart';
import '../../../_shared/database/dao/sync_meta_dao.dart';
import '../../../_shared/database/app_database.dart' as db;
import '../../../_shared/services/connectivity_service.dart';
import '../../../_shared/services/pending_submission.dart';
import '../../../_shared/services/pending_submission_risk.dart';

class CoreAuditSyncModule extends BaseSyncModule {
  final SyncApi _api;
  final OutboxDao _outboxDao;
  final GlobalRiskDao _globalRiskDao;
  final SubmissionRiskOutboxDao _submissionRiskOutboxDao;
  final SyncMetaDao _syncMetaDao;
  final ConnectivityService _connectivity;

  CoreAuditSyncModule({
    required SyncApi api,
    required OutboxDao outboxDao,
    required GlobalRiskDao globalRiskDao,
    required SubmissionRiskOutboxDao submissionRiskOutboxDao,
    required SyncMetaDao syncMetaDao,
    required ConnectivityService connectivity,
    required super.scheduleRetry,
  }) : _api = api,
       _outboxDao = outboxDao,
       _globalRiskDao = globalRiskDao,
       _submissionRiskOutboxDao = submissionRiskOutboxDao,
       _syncMetaDao = syncMetaDao,
       _connectivity = connectivity;

  @override
  int get priority => 10;

  DateTime? _lastSyncTimestamp;

  @override
  Future<void> executePull() async {
    await _pullDeltas();
  }

  @override
  Future<void> executePush() async {
    await _outboxDao.sweepSyncedSubmissions();
    await _drainSubmissions();
    if (!_connectivity.isOnline) return;
    await _drainRisks();
  }

  Future<void> _pullDeltas() async {
    _lastSyncTimestamp ??= await _syncMetaDao.get('global');
    final pullResult = await _api.pullDeltas(_lastSyncTimestamp);
    _lastSyncTimestamp = pullResult.serverTimestamp;
    if (_lastSyncTimestamp != null) {
      await _syncMetaDao.set('global', _lastSyncTimestamp!);
    }
    final globalRisks = await _api.pullGlobalRisks(_lastSyncTimestamp);
    for (final json in globalRisks) {
      await _globalRiskDao.upsertRisk(
        db.CachedGlobalRisksCompanion.insert(
          id: json['id'] as String,
          label: json['label'] as String,
          description: Value(json['description'] as String?),
          isActive: Value(json['isActive'] as bool? ?? true),
          createdAt: DateTime.parse(json['createdAt'] as String),
          updatedAt: DateTime.parse(json['updatedAt'] as String),
        ),
      );
    }
  }

  Future<void> _drainSubmissions() async {
    final eligibleRows = await _outboxDao.getEligiblePending();
    await processQueue<db.PendingSubmission>(
      eligibleRows,
      isOnline: () => _connectivity.isOnline,
      getRetryCount: (row) => row.retryCount,
      push: (dbRow) async {
        final answers = await _outboxDao.getAnswersForSubmission(dbRow.id);
        final hasGlobalRisk = await _submissionRiskOutboxDao.hasPendingRisks(
          dbRow.id,
        );
        await _api.pushSubmission(
          PendingSubmission(
            idempotencyKey: dbRow.idempotencyKey,
            createdAt: dbRow.createdAt,
            payload: jsonEncode({
              'id': dbRow.id,
              'templateId': dbRow.templateId,
              'storeId': dbRow.storeId,
              'clientScore': dbRow.clientScore,
              'sectionScores': dbRow.sectionScores,
              'notes': dbRow.notes,
              'gpsLat': dbRow.gpsLat,
              'gpsLng': dbRow.gpsLng,
              'status': 'completed',
              'idempotencyKey': dbRow.idempotencyKey,
              'targetSubmissionId': dbRow.targetSubmissionId,
              'hasGlobalRisk': hasGlobalRisk,
              'answers': answers.map(buildAnswerPayload).toList(),
            }),
          ),
        );
      },
      onPushSucceeded: (dbRow) => _outboxDao.markSynced(dbRow.id),
      onSuccess: (dbRow) => _outboxDao.removeSubmission(dbRow.id),
      onExhausted: (dbRow, error) async {
        final isBadRequest =
            error.contains('400') || error.contains('ClientFormatError');
        final isForbidden =
            error.contains('403') || error.toLowerCase().contains('forbidden');
        await _outboxDao.updateSyncStatus(
          dbRow.id,
          'exhausted',
          error: isBadRequest
              ? 'FATAL 400: $error'
              : isForbidden
              ? 'FATAL 403: Permission denied. Role may have changed.'
              : error,
        );
      },
      onRetry: (dbRow, newRetryCount, nextRetry, error) =>
          _outboxDao.updateSyncStatus(
            dbRow.id,
            'pending',
            retryCount: newRetryCount,
            nextRetryAt: nextRetry,
            error: error,
          ),
      isFatalError: (error) {
        final message = error.toString();
        return message.contains('400') ||
            message.contains('ClientFormatError') ||
            message.contains('403') ||
            message.toLowerCase().contains('forbidden');
      },
    );
  }

  Future<void> _drainRisks() async {
    final pendingRisks = await _submissionRiskOutboxDao.getEligiblePending();
    await processQueue<db.SubmissionRiskOutboxEntry>(
      pendingRisks,
      isOnline: () => _connectivity.isOnline,
      getRetryCount: (row) => row.retryCount,
      push: (row) => _api.pushSubmissionRisk(
        PendingSubmissionRisk(
          submissionId: row.submissionId,
          globalRiskId: row.globalRiskId,
        ),
      ),
      onSuccess: (row) => _submissionRiskOutboxDao.remove(row.id),
      onExhausted: (row, error) =>
          _submissionRiskOutboxDao.markExhausted(row.id, error),
      onRetry: (row, newRetryCount, nextRetry, error) =>
          _submissionRiskOutboxDao.updateRetry(
            row.id,
            newRetryCount,
            nextRetry,
            error,
          ),
      isFatalError: (_) => false,
      onConflict: (row) => _submissionRiskOutboxDao.remove(row.id),
    );
  }

  static Map<String, dynamic> buildAnswerPayload(dynamic a) {
    return {
      'criteriaId': a.criteriaId,
      'value': a.value,
      'numericValue': a.numericValue,
      'note': a.note,
      'photoUrl': a.photoUrl,
      'isRepeatedError': a.isRepeatedError,
      'repeatedFaults': a.repeatedFaults,
      'isCcp': a.isCcp,
      'isRisk': a.isRisk,
    };
  }
}
