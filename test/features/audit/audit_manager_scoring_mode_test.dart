import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/native.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/scoring_models.dart';

import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';

import 'package:checkly/features/audit/services/draft_service.dart';

class MockSubmissionApiService extends Mock implements SubmissionApiService {}
class MockOutboxDao extends Mock implements OutboxDao {}
class MockDraftService extends Mock implements DraftService {}

void main() {
  setUpAll(() async {
    await GetIt.instance.reset();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    GetIt.instance.registerSingleton<DatabaseService>(DatabaseService.forTesting(db));
  });

  group('AuditManager.scoringMode', () {
    test('returns accumulation when template is configured for maturity assessment', () async {
      final template = TemplateTreeDto(
        id: 'tpl-acc',
        title: 'Maturity Template',
        type: 'audit',
        version: 1,
        isActive: true,
        scoringLogicConfig: '{"scoringMode": "accumulation"}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groups: [],
      );

      final draftService = MockDraftService();
      when(() => draftService.loadDraft(any())).thenAnswer((_) async => null);
      when(() => draftService.scheduleSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes'),
      )).thenReturn(null);

      final manager = AuditManager(
        api: MockSubmissionApiService(),
        outbox: MockOutboxDao(),
        draftService: draftService,
      ); 
      await manager.startAudit(template, 'store-1');

      expect(manager.scoringMode, ScoringMode.accumulation);
    });

    test('defaults to penalty when no template is loaded', () {
      final manager = AuditManager(
        api: MockSubmissionApiService(),
        outbox: MockOutboxDao(),
        draftService: MockDraftService(),
      );
      expect(manager.scoringMode, ScoringMode.penalty);
    });
  });
}
