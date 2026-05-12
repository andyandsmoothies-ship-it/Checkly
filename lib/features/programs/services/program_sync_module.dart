import 'package:drift/drift.dart' show Value;

import '../../../_shared/services/sync_module.dart';
import '../../../_shared/services/sync_api.dart';
import '../../../_shared/database/dao/program_outbox_dao.dart';
import '../../../_shared/database/dao/sync_meta_dao.dart';
import '../../../_shared/database/app_database.dart' as db;

class ProgramSyncModule extends BaseSyncModule {
  final SyncApi _api;
  final ProgramOutboxDao _outboxDao;
  final SyncMetaDao _syncMetaDao;

  ProgramSyncModule({
    required SyncApi api,
    required ProgramOutboxDao outboxDao,
    required SyncMetaDao syncMetaDao,
    required super.scheduleRetry,
  }) : _api = api,
       _outboxDao = outboxDao,
       _syncMetaDao = syncMetaDao;

  @override
  int get priority => 30;

  @override
  Future<void> executePull() async {
    await _pullProgramAssignments();
  }

  @override
  Future<void> executePush() async {
    // Migrated: Evidence pushing is now handled by standard Audit outbox logic
    // via SubmissionSyncModule. Program module only pulls assignments.
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
          templateId: Value(json['templateId'] as String?),
          deadline: DateTime.parse(json['deadline'] as String),
          status: Value(json['status'] as String? ?? 'pending'),
          rejectionComment: Value(json['rejectionComment'] as String?),
          createdAt: DateTime.parse(json['createdAt'] as String),
        ),
      );
    }
    await _syncMetaDao.set('program_assignments', DateTime.now().toUtc());
  }
}
