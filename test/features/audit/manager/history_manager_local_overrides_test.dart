import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/submission_dao.dart';
import 'package:checkly/features/audit/manager/history_manager.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';

class MockSubmissionApiService extends Mock implements SubmissionApiService {}

class MockDraftService extends Mock implements DraftService {}

void main() {
  late AppDatabase db;
  late SubmissionDao submissionDao;
  late OutboxDao outboxDao;
  late MockSubmissionApiService api;
  late MockDraftService draftService;
  late HistoryManager manager;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    submissionDao = SubmissionDao(db);
    outboxDao = OutboxDao(db);
    api = MockSubmissionApiService();
    draftService = MockDraftService();

    when(
      () => draftService.getAllDraftKeys(),
    ).thenAnswer((_) async => {'tpl-1:store-1:user-1', 'tpl-2:store-2:user-2'});
    when(
      () => api.getSubmissions(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenThrow(Exception('offline'));

    manager = HistoryManager(
      api: api,
      dao: submissionDao,
      draftService: draftService,
      outboxDao: outboxDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'HistoryManager_LoadHistory_HydratesLocalDraftAndOutboxMetadataWithoutManagerDbAccess',
    () async {
      final now = DateTime.utc(2026, 5, 2, 10);
      final draftSavedAt = DateTime.utc(2026, 5, 2, 9, 30);

      await db.batch((batch) {
        batch.insertAll(db.cachedTemplates, [
          CachedTemplatesCompanion.insert(
            id: 'tpl-1',
            title: 'Template One',
            type: 'audit',
            createdAt: now,
            updatedAt: now,
          ),
          CachedTemplatesCompanion.insert(
            id: 'tpl-2',
            title: 'Template Two',
            type: 'ops',
            createdAt: now,
            updatedAt: now,
          ),
          CachedTemplatesCompanion.insert(
            id: 'tpl-3',
            title: 'Template Three',
            type: 'safety',
            createdAt: now,
            updatedAt: now,
          ),
        ]);
        batch.insertAll(db.cachedStores, [
          CachedStoresCompanion.insert(
            id: 'store-1',
            name: 'Store One',
            createdAt: now,
            updatedAt: now,
          ),
          CachedStoresCompanion.insert(
            id: 'store-2',
            name: 'Store Two',
            createdAt: now,
            updatedAt: now,
          ),
          CachedStoresCompanion.insert(
            id: 'store-3',
            name: 'Store Three',
            createdAt: now,
            updatedAt: now,
          ),
        ]);
        batch.insertAll(db.cachedSubmissions, [
          CachedSubmissionsCompanion.insert(
            id: 'server-scheduled',
            templateId: const Value('tpl-1'),
            templateTitle: const Value('Template One'),
            templateType: const Value('audit'),
            storeId: const Value('store-1'),
            storeName: const Value('Store One'),
            status: 'scheduled',
            createdAt: DateTime.utc(2026, 5, 1, 8),
          ),
        ]);
        batch.insertAll(db.draftAnswers, [
          DraftAnswersCompanion.insert(
            draftKey: 'tpl-2:store-2:user-2',
            answersJson: '{}',
            savedAt: draftSavedAt,
          ),
        ]);
      });

      await outboxDao.insertSubmission(
        PendingSubmissionsCompanion.insert(
          id: 'outbox-1',
          templateId: 'tpl-3',
          storeId: 'store-3',
          clientScore: 91.5,
          idempotencyKey: 'idem-1',
          createdAt: DateTime.utc(2026, 5, 2, 9),
        ),
      );

      await manager.loadHistory();

      final hydrated = manager.submissions.value;
      expect(hydrated, hasLength(3));

      final scheduled = hydrated.singleWhere((s) => s.id == 'server-scheduled');
      expect(
        scheduled.status,
        'draft',
        reason:
            'Matching local draft keys must override scheduled rows in memory',
      );

      final localDraft = hydrated.singleWhere(
        (s) => s.id == 'local_draft_tpl-2:store-2:user-2',
      );
      expect(localDraft.templateTitle, 'Template Two');
      expect(localDraft.templateType, 'ops');
      expect(localDraft.storeName, 'Store Two');
      expect(localDraft.createdAt.isAtSameMomentAs(draftSavedAt), isTrue);

      final localOutbox = hydrated.singleWhere(
        (s) => s.id == 'local_outbox_outbox-1',
      );
      expect(localOutbox.templateTitle, 'Template Three');
      expect(localOutbox.templateType, 'safety');
      expect(localOutbox.storeName, 'Store Three');
      expect(localOutbox.status, 'syncing');
      expect(localOutbox.totalScore, 91.5);
    },
  );
}
