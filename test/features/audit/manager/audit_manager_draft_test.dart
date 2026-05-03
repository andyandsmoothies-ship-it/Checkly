import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

class MockOutboxDao extends Mock implements OutboxDao {}
class MockGlobalRiskDao extends Mock implements GlobalRiskDao {}
class MockSubmissionRiskOutboxDao extends Mock implements SubmissionRiskOutboxDao {}
class MockDraftService extends Mock implements DraftService {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('AuditManagerDraft', () {
    late AuditManager manager;
    late MockOutboxDao mockOutboxDao;
    late MockGlobalRiskDao mockGlobalRiskDao;
    late MockSubmissionRiskOutboxDao mockRiskOutboxDao;
    late MockDraftService mockDraftService;
    late MockConnectivityService mockConnectivity;

    final template = TemplateTreeDto(
      id: 'template-1',
      title: 'Audit',
      description: '',
      type: 'audit',
      version: 1,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scoringLogicConfig: '{"scoringMode":"penalty"}',
      groups: [
        GroupDto(
          id: 'g-1',
          title: 'Group 1',
          weight: 100,
          orderIndex: 0,
          criteria: [
            CriterionDto(
              id: 'c-1',
              label: 'C1',
              inputType: 'pass_fail',
              isCcp: false,
              isRisk: false,
              orderIndex: 0,
            )
          ],
          children: [],
        )
      ],
    );

    setUp(() {
      mockOutboxDao = MockOutboxDao();
      mockGlobalRiskDao = MockGlobalRiskDao();
      mockRiskOutboxDao = MockSubmissionRiskOutboxDao();
      mockDraftService = MockDraftService();
      mockConnectivity = MockConnectivityService();

      when(() => mockDraftService.loadDraft(any())).thenAnswer((_) async => null);
      when(() => mockDraftService.dispose()).thenReturn(null);
      when(() => mockDraftService.deleteDraft(any())).thenAnswer((_) async {});
      when(() => mockDraftService.scheduleSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes')
      )).thenReturn(null);
      when(() => mockGlobalRiskDao.getActiveRisks()).thenAnswer((_) async => []);

      manager = AuditManager(
        outbox: mockOutboxDao,
        globalRiskDao: mockGlobalRiskDao,
        riskOutboxDao: mockRiskOutboxDao,
        draftService: mockDraftService,
        connectivity: mockConnectivity,
      );
    });

    test('TC-12-01: scheduleDraftSaveLogic saves to DraftService and sets saved time', () async {
      await manager.startAudit(template, 'store-1');
      
      manager.setAnswer('c-1', value: 'yes');

      verify(() => mockDraftService.scheduleSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes')
      )).called(greaterThan(0));
      
      expect(manager.draftSavedAt, isNotNull);
    });

    test('TC-12-02: restoreDraftLogic restores valid answers and notes from pendingDraft', () async {
      when(() => mockDraftService.loadDraft(any())).thenAnswer((_) async => DraftData(
        answersMap: {
          'c-1': {
            'criteriaId': 'c-1', 
            'value': 'no', 
            'numericValue': null, 
            'note': 'Broken', 
            'photoUrl': null,
            'isRepeatedError': false,
            'repeatedFaultCount': 0,
            'isCcp': false, 
            'isRisk': false
          }
        },
        notes: 'Store looks okay',
        savedAt: DateTime.now(),
      ));

      await manager.startAudit(template, 'store-1');
      
      expect(manager.hasDraft, isTrue);
      
      manager.restoreDraft();
      
      expect(manager.answers['c-1']?.value, 'no');
      expect(manager.answers['c-1']?.note, 'Broken');
      expect(manager.notes, 'Store looks okay');
      expect(manager.hasDraft, isFalse);
    });

    test('TC-12-03: restoreDraftLogic silently skips corrupted answer formats', () async {
      when(() => mockDraftService.loadDraft(any())).thenAnswer((_) async => DraftData(
        answersMap: {
          'c-1': {
            'criteriaId': null, // corrupted, will throw exception in AuditAnswer.fromJson
            'value': 123 // corrupted type
          }
        },
        savedAt: DateTime.now(),
      ));

      await manager.startAudit(template, 'store-1');
      
      manager.restoreDraft();
      
      // Should remain untouched
      expect(manager.answers['c-1']?.value, isNull);
    });

    test('TC-12-04: discardDraftLogic deletes draft key and nullifies pending draft', () async {
      when(() => mockDraftService.loadDraft(any())).thenAnswer((_) async => DraftData(
        answersMap: {},
        savedAt: DateTime.now(),
      ));

      await manager.startAudit(template, 'store-1');
      
      manager.discardDraft();

      verify(() => mockDraftService.deleteDraft(any())).called(1);
      expect(manager.hasDraft, isFalse);
    });

    test('TC-12-05: forceSaveLogic bypasses debounce and completes immediately', () async {
      when(() => mockDraftService.flushSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes')
      )).thenAnswer((_) async {});

      await manager.startAudit(template, 'store-1');
      
      await manager.forceSave();
      
      verify(() => mockDraftService.flushSave(
        draftKey: any(named: 'draftKey'),
        answersMap: any(named: 'answersMap'),
        notes: any(named: 'notes')
      )).called(1);
    });
  });
}
