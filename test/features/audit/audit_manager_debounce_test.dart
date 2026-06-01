import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';

import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';

class MockOutboxDao extends Mock implements OutboxDao {}
class MockGlobalRiskDao extends Mock implements GlobalRiskDao {}
class MockSubmissionRiskOutboxDao extends Mock implements SubmissionRiskOutboxDao {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockDraftService extends Mock implements DraftService {}

void _registerFallbacks() {
  registerFallbackValue(
    PendingSubmissionsCompanion(
      id: const Value(''),
      templateId: const Value(''),
      storeId: const Value(''),
      clientScore: const Value(0.0),
      idempotencyKey: const Value(''),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    ),
  );
  registerFallbackValue(<PendingAnswersCompanion>[]);
}

CriterionDto _crit(String id, {double weight = 10}) => CriterionDto(
  id: id,
  label: 'Q $id',
  description: null,
  inputType: 'numeric',
  pointsWeight: weight,
  isCcp: false,
  isRisk: false,
  minusImpact: null,
  orderIndex: 0,
  metadata: null,
);

GroupDto _group(String id, List<CriterionDto> criteria) => GroupDto(
  id: id,
  title: 'Group $id',
  description: null,
  weight: 1,
  maxDeductionPoints: null,
  minusPerFault: null,
  orderIndex: 0,
  metadata: null,
  children: const [],
  criteria: criteria,
);

TemplateTreeDto _template({List<GroupDto>? groups}) => TemplateTreeDto(
  id: 'tpl-1',
  title: 'Test Template',
  description: null,
  type: 'audit',
  version: 1,
  scoringLogicConfig: null,
  displayNoun: 'audit',
  isActive: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  groups: groups ?? [_group('g1', [_crit('c1'), _crit('c2')])],
);

AuditManager _manager({
  MockOutboxDao? outbox,
  MockConnectivityService? connectivity,
  MockDraftService? draft,
}) {
  final isExternalDraft = draft != null;
  final mockDraft = draft ?? MockDraftService();

  if (!isExternalDraft) {
    when(() => mockDraft.loadDraft(any())).thenAnswer((_) async => null);
    when(
      () => mockDraft.scheduleSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes'),
      ),
    ).thenReturn(null);
    when(() => mockDraft.dispose()).thenReturn(null);
    when(() => mockDraft.deleteDraft(any())).thenAnswer((_) async {});
  }

  final mockGlobalRisk = MockGlobalRiskDao();
  final mockRiskOutbox = MockSubmissionRiskOutboxDao();

  when(() => mockGlobalRisk.getActiveRisks()).thenAnswer((_) async => []);

  return AuditManager(
    outbox: outbox ?? MockOutboxDao(),
    globalRiskDao: mockGlobalRisk,
    riskOutboxDao: mockRiskOutbox,
    connectivity: connectivity,
    draftService: mockDraft,
  );
}

void main() {
  setUpAll(_registerFallbacks);

  late AppDatabase testDb;
  final di = GetIt.instance;

  setUp(() async {
    await di.reset();
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    di.registerSingleton<DatabaseService>(DatabaseService.forTesting(testDb));
  });

  tearDown(() async {
    await testDb.close();
    await di.reset();
  });

  group('AuditManager Compliance Score Calculation Debounce Tests', () {
    test('TC-DEBOUNCE-01: Rapid answer updates debounce score recalculation by 200ms', () async {
      fakeAsync((async) {
        // Arrange
        final m = _manager();
        m.startAudit(
          _template(
            groups: [
              _group('g1', [_crit('c1', weight: 10), _crit('c2', weight: 20)]),
            ],
          ),
          'store-1',
        );

        // Score starts at 100
        expect(m.liveScore, 100.0);

        // Act: update answers rapidly under 200ms
        m.setAnswer('c1', value: 'non_conform', numericValue: 1);
        async.elapse(const Duration(milliseconds: 50));
        
        // Answers map must update immediately
        expect(m.answers['c1']?.value, 'non_conform');
        // Live score must NOT have changed yet because of 200ms debounce
        expect(m.liveScore, 100.0);

        m.setAnswer('c2', value: 'non_conform', numericValue: 1);
        async.elapse(const Duration(milliseconds: 100));

        // Answers map must update immediately
        expect(m.answers['c2']?.value, 'non_conform');
        // Still 100.0 since last mutation was 100ms ago
        expect(m.liveScore, 100.0);

        // Elapse past the 200ms mark from the last mutation (100ms remaining + buffer)
        async.elapse(const Duration(milliseconds: 105));

        // Now liveScore should be updated (c1 weight=10, c2 weight=20, so deductions dropped the score)
        expect(m.liveScore, lessThan(100.0));
      });
    });

    test('TC-DEBOUNCE-02: Submit cancels debounce timer and triggers immediate calculation', () async {
      fakeAsync((async) {
        // Arrange
        final mockOutbox = MockOutboxDao();
        when(() => mockOutbox.insertSubmissionWithAnswers(any(), any())).thenAnswer((_) async {});

        final m = _manager(outbox: mockOutbox);
        m.startAudit(
          _template(
            groups: [
              _group('g1', [_crit('c1', weight: 10)]),
            ],
          ),
          'store-1',
        );

        expect(m.liveScore, 100.0);

        // Act: modify answer
        m.setAnswer('c1', value: 'non_conform', numericValue: 1);
        
        // Immediate submit within 200ms
        m.submitAudit();
        
        // Assert: Live score must be recalculated synchronously immediately during submit
        expect(m.liveScore, lessThan(100.0));

        // Let async timer loop drain to make sure no pending timers remain
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
      });
    });
  });
}
