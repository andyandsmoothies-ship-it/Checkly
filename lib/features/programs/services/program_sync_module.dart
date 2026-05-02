import 'dart:convert';
import 'package:drift/drift.dart' show Value;

import '../../../_shared/services/sync_module.dart';
import '../../../_shared/services/sync_api.dart';
import '../../../_shared/database/dao/program_outbox_dao.dart';
import '../../../_shared/database/dao/sync_meta_dao.dart';
import '../../../_shared/database/app_database.dart' as db;
import '../../../_shared/services/connectivity_service.dart';

class ProgramSyncModule extends BaseSyncModule {
  final SyncApi _api;
  final ProgramOutboxDao _outboxDao;
  final SyncMetaDao _syncMetaDao;
  final ConnectivityService _connectivity;

  ProgramSyncModule({
    required SyncApi api,
    required ProgramOutboxDao outboxDao,
    required SyncMetaDao syncMetaDao,
    required ConnectivityService connectivity,
    required super.scheduleRetry,
  }) : _api = api,
       _outboxDao = outboxDao,
       _syncMetaDao = syncMetaDao,
       _connectivity = connectivity;

  @override
  int get priority => 30;

  @override
  Future<void> executePull() async {
    await _pullProgramAssignments();
  }

  @override
  Future<void> executePush() async {
    await _drainProgramEvidence();
    if (!_connectivity.isOnline) return;
    await _drainProgramPhotos();
  }

  Future<void> _pullProgramAssignments() async {
    final assignments = await _api.pullProgramAssignments();
    await _outboxDao.deleteAllCachedAssignments();
    for (final json in assignments) {
      await _outboxDao.upsertCachedAssignment(
        db.CachedProgramAssignmentsCompanion.insert(
          id: json['id'] as String,
          programId: json['programId'] as String,
          programTitle: json['programTitle'] as String,
          category: json['category'] as String,
          deadline: DateTime.parse(json['deadline'] as String),
          status: Value(json['status'] as String? ?? 'pending'),
          rejectionComment: Value(json['rejectionComment'] as String?),
          createdAt: DateTime.parse(json['createdAt'] as String),
        ),
      );
    }
    await _syncMetaDao.set('program_assignments', DateTime.now().toUtc());
  }

  Future<void> _drainProgramEvidence() async {
    final pending = await _outboxDao.getEligiblePending();
    await processQueue<db.PendingProgramSubmission>(
      pending,
      isOnline: () => _connectivity.isOnline,
      getRetryCount: (row) => row.retryCount,
      push: (row) async {
        final evidenceItems =
            jsonDecode(row.evidenceItemsJson) as List<dynamic>;
        await _api.pushProgramEvidence(
          row.assignmentId,
          evidenceItems.cast<Map<String, dynamic>>(),
        );
      },
      onSuccess: (row) async {
        await _outboxDao.remove(row.id);
        await _outboxDao.upsertCachedAssignment(
          db.CachedProgramAssignmentsCompanion(
            id: Value(row.assignmentId),
            status: const Value('submitted'),
          ),
        );
      },
      onExhausted: (row, error) => _outboxDao.markExhausted(
        row.id,
        error == 'Max retries exceeded' ? error : 'FATAL: $error',
      ),
      onRetry: (row, newRetryCount, nextRetry, error) =>
          _outboxDao.updateRetry(row.id, newRetryCount, nextRetry, error),
      isFatalError: (error) {
        final message = error.toString();
        return message.contains('400') ||
            message.contains('403') ||
            message.contains('404');
      },
    );
  }

  Future<void> _drainProgramPhotos() async {
    final pendingPhotos = await _outboxDao.getPendingPhotos();
    await processQueue<db.PendingProgramPhoto>(
      pendingPhotos,
      isOnline: () => _connectivity.isOnline,
      getRetryCount: (photo) => photo.retryCount,
      push: (photo) => _api.pushProgramPhoto(photo.id, photo.localPath),
      onSuccess: (photo) => _outboxDao.removePhoto(photo.id),
      onExhausted: (photo, error) => _outboxDao.markPhotoExhausted(
        photo.id,
        error == 'Max retries exceeded' ? error : 'FATAL: $error',
      ),
      onRetry: (photo, newRetryCount, nextRetry, error) => _outboxDao
          .updatePhotoRetry(photo.id, newRetryCount, nextRetry, error),
      isFatalError: (error) {
        final message = error.toString();
        return message.contains('400') ||
            message.contains('403') ||
            message.contains('404') ||
            message.contains('415');
      },
    );
  }
}
