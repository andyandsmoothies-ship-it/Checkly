import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/native.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/services/scoring_mode.dart';

import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/features/audit/services/draft_service.dart';

class MockOutboxDao extends Mock implements OutboxDao {}

class MockGlobalRiskDao extends Mock implements GlobalRiskDao {}

class MockSubmissionRiskOutboxDao extends Mock
    implements SubmissionRiskOutboxDao {}

class MockDraftService extends Mock implements DraftService {}

void main() {
  setUpAll(() async {
    await GetIt.instance.reset();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    GetIt.instance.registerSingleton<DatabaseService>(
      DatabaseService.forTesting(db),
    );
  });

  group('AuditManager.scoringMode', () {
    test(
      'returns accumulation when template is configured for maturity assessment',
      () async {
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
        when(
          () => draftService.scheduleSave(
            draftKey: any(named: 'draftKey'),
            answersMap: any(named: 'answersMap'),
            notes: any(named: 'notes'),
          ),
        ).thenReturn(null);

        final mockGlobalRisk = MockGlobalRiskDao();
        when(() => mockGlobalRisk.getActiveRisks()).thenAnswer((_) async => []);

        final manager = AuditManager(
          outbox: MockOutboxDao(),
          globalRiskDao: mockGlobalRisk,
          riskOutboxDao: MockSubmissionRiskOutboxDao(),
          draftService: draftService,
        );
        await manager.startAudit(template, 'store-1');

        expect(manager.scoringMode, ScoringMode.accumulation);
      },
    );

    test('defaults to penalty when no template is loaded', () {
      final manager = AuditManager(
        outbox: MockOutboxDao(),
        globalRiskDao: MockGlobalRiskDao(),
        riskOutboxDao: MockSubmissionRiskOutboxDao(),
        draftService: MockDraftService(),
      );
      expect(manager.scoringMode, ScoringMode.penalty);
    });
  });
}
