import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/model/create_submission_request.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/database_service.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockSubmissionApiService extends Mock implements SubmissionApiService {}

class MockOutboxDao extends Mock implements OutboxDao {}

class MockGlobalRiskDao extends Mock implements GlobalRiskDao {}

class MockSubmissionRiskOutboxDao extends Mock
    implements SubmissionRiskOutboxDao {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockDraftService extends Mock implements DraftService {}

// ── Fallback registrations (required by mocktail for non-nullable args) ───────

void _registerFallbacks() {
  registerFallbackValue(CreateSubmissionRequest(templateId: '', storeId: ''));
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

// ── Helpers ──────────────────────────────────────────────────────────────────

CriterionDto _crit(String id, {double weight = 5}) => CriterionDto(
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
  groups:
      groups ??
      [
        _group('g1', [_crit('c1'), _crit('c2')]),
      ],
);

/// Creates an [AuditManager] with all dependencies injected.
/// DraftService stubs are applied by default.
AuditManager _manager({
  MockSubmissionApiService? api,
  MockOutboxDao? outbox,
  MockConnectivityService? connectivity,
  MockDraftService? draft,
}) {
  final isExternalDraft = draft != null;
  final mockDraft = draft ?? MockDraftService();

  // Only apply default stubs when we create the draft mock.
  // Externally-provided mocks keep their own stubs intact.
  if (!isExternalDraft) {
    when(() => mockDraft.loadDraft(any())).thenAnswer((_) async => null);
    when(
      () => mockDraft.scheduleSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes'),
      ),
    ).thenReturn(null);
    // dispose() called at start of submitAudit()
    when(() => mockDraft.dispose()).thenReturn(null);
    // deleteDraft() called inside submitAudit() after outbox insert
    when(() => mockDraft.deleteDraft(any())).thenAnswer((_) async {});
  }

  final mockGlobalRisk = MockGlobalRiskDao();
  final mockRiskOutbox = MockSubmissionRiskOutboxDao();

  // Default stubs — tests that need different behaviour can override _manager().
  when(() => mockGlobalRisk.getActiveRisks()).thenAnswer((_) async => []);

  return AuditManager(
    api: api ?? MockSubmissionApiService(),
    outbox: outbox ?? MockOutboxDao(),
    globalRiskDao: mockGlobalRisk,
    riskOutboxDao: mockRiskOutbox,
    connectivity: connectivity,
    draftService: mockDraft,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(_registerFallbacks);

  late AppDatabase testDb;
  final di = GetIt.instance;

  setUp(() async {
    // Reset GetIt to a clean state before each test to prevent cross-file leaks
    await di.reset();
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    di.registerSingleton<DatabaseService>(DatabaseService.forTesting(testDb));
  });

  tearDown(() async {
    await testDb.close();
    await di.reset();
  });

  // ── Group 1: Initialization ─────────────────────────────────────────────

  group('startAudit', () {
    test('pre-populates answers for ALL criteria across all groups', () async {
      final m = _manager();
      final template = _template(
        groups: [
          _group('g1', [_crit('c1'), _crit('c2')]),
          _group('g2', [_crit('c3')]),
        ],
      );

      await m.startAudit(template, 'store-1');

      expect(m.answers.keys, containsAll(['c1', 'c2', 'c3']));
      expect(m.answers.length, 3);
    });

    test(
      'liveScore is 100 after startAudit with unanswered template',
      () async {
        final m = _manager();
        await m.startAudit(_template(), 'store-1');
        expect(m.liveScore, 100.0);
      },
    );

    test('calls DraftService.loadDraft once', () async {
      final mockDraft = MockDraftService();
      when(() => mockDraft.loadDraft(any())).thenAnswer((_) async => null);
      when(
        () => mockDraft.scheduleSave(
          draftKey: any(named: 'draftKey'),
          answersMap: any(named: 'answersMap'),
          notes: any(named: 'notes'),
        ),
      ).thenReturn(null);

      final m = _manager(draft: mockDraft);
      await m.startAudit(_template(), 'store-1');

      verify(() => mockDraft.loadDraft(any())).called(1);
    });
  });

  // ── Group 2: Answer updates & score recalculation ─────────────────────

  group('setAnswer', () {
    test('setting non_conform reduces liveScore', () async {
      final m = _manager();
      await m.startAudit(
        _template(
          groups: [
            _group('g1', [_crit('c1', weight: 10)]),
          ],
        ),
        'store-1',
      );

      m.setAnswer('c1', value: 'non_conform', numericValue: 1);

      expect(m.liveScore, lessThan(100.0));
    });

    test('setCcp on a non_conform answer drops score to 0', () async {
      final m = _manager();
      await m.startAudit(
        _template(
          groups: [
            _group('g1', [_crit('c1')]),
          ],
        ),
        'store-1',
      );

      m.setAnswer('c1', value: 'non_conform', numericValue: 1);
      m.setCcp('c1', true);

      expect(m.liveScore, 0.0);
    });

    test('setAnswer triggers DraftService.scheduleSave', () async {
      final mockDraft = MockDraftService();
      when(() => mockDraft.loadDraft(any())).thenAnswer((_) async => null);
      when(
        () => mockDraft.scheduleSave(
          draftKey: any(named: 'draftKey'),
          answersMap: any(named: 'answersMap'),
          notes: any(named: 'notes'),
        ),
      ).thenReturn(null);

      final m = _manager(draft: mockDraft);
      await m.startAudit(_template(), 'store-1');
      m.setAnswer('c1', value: 'conform');

      verify(
        () => mockDraft.scheduleSave(
          draftKey: any(named: 'draftKey'),
          answersMap: any(named: 'answersMap'),
          notes: any(named: 'notes'),
        ),
      ).called(2);
    });
  });

  // ── Group 3: Draft behavior ────────────────────────────────────────────

  group('restoreDraft', () {
    test('merges draft answer values into live answer map', () async {
      final mockDraft = MockDraftService();
      when(() => mockDraft.loadDraft(any())).thenAnswer(
        (_) async => DraftData(
          answersMap: {
            'c1': {
              'criteriaId': 'c1',
              'value': 'non_conform',
              'numericValue': 2.0,
              'note': 'restored note',
              'photoUrl': null,
              'repeatedFaultCount': 0,
              'isCcp': false,
              'isRisk': false,
            },
          },
          savedAt: DateTime.now(),
        ),
      );
      when(
        () => mockDraft.scheduleSave(
          draftKey: any(named: 'draftKey'),
          answersMap: any(named: 'answersMap'),
          notes: any(named: 'notes'),
        ),
      ).thenReturn(null);

      final m = _manager(draft: mockDraft);
      await m.startAudit(_template(), 'store-1');

      expect(m.hasDraft, isTrue);
      m.restoreDraft();

      expect(m.answers['c1']?.value, 'non_conform');
      expect(m.answers['c1']?.numericValue, 2.0);
      expect(m.answers['c1']?.note, 'restored note');
      expect(m.hasDraft, isFalse);
    });

    test(
      'discardDraft clears the pending draft and hasDraft → false',
      () async {
        final mockDraft = MockDraftService();
        when(() => mockDraft.loadDraft(any())).thenAnswer(
          (_) async => DraftData(answersMap: {}, savedAt: DateTime.now()),
        );
        when(
          () => mockDraft.scheduleSave(
            draftKey: any(named: 'draftKey'),
            answersMap: any(named: 'answersMap'),
            notes: any(named: 'notes'),
          ),
        ).thenReturn(null);
        when(() => mockDraft.deleteDraft(any())).thenAnswer((_) async {});

        final m = _manager(draft: mockDraft);
        await m.startAudit(_template(), 'store-1');

        expect(m.hasDraft, isTrue);
        m.discardDraft();
        expect(m.hasDraft, isFalse);
      },
    );
  });

  // ── Group 4: Submission orchestration (offline-first) ─────────────────

  group('submitAudit', () {
    test('inserts to OutboxDao and skips API when offline', () async {
      final mockOutbox = MockOutboxDao();
      final mockApi = MockSubmissionApiService();
      final mockConnectivity = MockConnectivityService();

      when(
        () => mockOutbox.insertSubmissionWithAnswers(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockConnectivity.isOnline).thenReturn(false);

      final m = _manager(
        outbox: mockOutbox,
        api: mockApi,
        connectivity: mockConnectivity,
      );
      await m.startAudit(_template(), 'store-1');
      await m.submitAudit();

      verify(
        () => mockOutbox.insertSubmissionWithAnswers(any(), any()),
      ).called(1);
      verifyNever(() => mockApi.createSubmission(any()));
      expect(m.wasQueuedOffline, isTrue);
    });

    test(
      'inserts to outbox and marks wasQueuedOffline=false when online',
      () async {
        final mockOutbox = MockOutboxDao();
        final mockConnectivity = MockConnectivityService();

        when(
          () => mockOutbox.insertSubmissionWithAnswers(any(), any()),
        ).thenAnswer((_) async {});
        when(() => mockConnectivity.isOnline).thenReturn(true);

        final m = _manager(outbox: mockOutbox, connectivity: mockConnectivity);
        await m.startAudit(_template(), 'store-1');
        await m.submitAudit();

        verify(
          () => mockOutbox.insertSubmissionWithAnswers(any(), any()),
        ).called(1);
        expect(m.wasQueuedOffline, isFalse);
      },
    );
  });
}
