import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/audit/services/draft_service.dart';
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/_shared/database/app_database.dart';

class MockOutboxDao extends Mock implements OutboxDao {}
class MockGlobalRiskDao extends Mock implements GlobalRiskDao {}
class MockSubmissionRiskOutboxDao extends Mock implements SubmissionRiskOutboxDao {}
class MockDraftService extends Mock implements DraftService {}
class MockConnectivityService extends Mock implements ConnectivityService {}

class FakePendingSubmissionsCompanion extends Fake implements PendingSubmissionsCompanion {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePendingSubmissionsCompanion());
  });

  group('AuditManagerSubmit Transitions', () {
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
      when(() => mockGlobalRiskDao.getActiveRisks()).thenAnswer((_) async => []);

      manager = AuditManager(
        outbox: mockOutboxDao,
        globalRiskDao: mockGlobalRiskDao,
        riskOutboxDao: mockRiskOutboxDao,
        draftService: mockDraftService,
        connectivity: mockConnectivity,
      );
    });

    test('TC-11-01: submitAudit drops concurrent calls silently (mutex)', () async {
      await manager.startAudit(template, 'store-1');
      manager.setAnswer('c-1', value: 'yes');
      
      final completer = Completer<void>();
      when(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any()))
          .thenAnswer((_) => completer.future);

      final firstCall = manager.submitAudit();
      expect(manager.isSubmitting, isTrue);

      final secondCall = manager.submitAudit();
      // Only 1 call to DAO
      verify(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any())).called(1);

      completer.complete();
      await firstCall;
      await secondCall;
      expect(manager.isSubmitting, isFalse);
    });

    test('TC-11-02: submitAudit sets error if answers are empty', () async {
      // Create template with NO criteria so answers map is empty, which throws inner Exception
      final emptyTemplate = TemplateTreeDto(
        id: 'template-empty',
        title: 'Empty',
        description: '',
        type: 'audit',
        version: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        scoringLogicConfig: '{"scoringMode":"penalty"}',
        groups: [],
      );

      await manager.startAudit(emptyTemplate, 'store-1');
      await manager.submitAudit();

      expect(manager.error, 'Submission failed. Please try again.');
      verifyNever(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any()));
    });

    test('TC-11-03: submitAudit inserts atomic submission and deletes draft', () async {
      when(() => mockConnectivity.isOnline).thenReturn(true);
      when(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any())).thenAnswer((_) async {});

      await manager.startAudit(template, 'store-1');
      manager.setAnswer('c-1', value: 'yes');

      await manager.submitAudit();

      verify(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any())).called(1);
      verify(() => mockDraftService.deleteDraft(any())).called(1);
      expect(manager.error, isNull);
      expect(manager.wasQueuedOffline, isFalse);
    });

    test('TC-11-04: submitAudit sets _wasQueuedOffline=true if offline', () async {
      when(() => mockConnectivity.isOnline).thenReturn(false);
      when(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any())).thenAnswer((_) async {});

      await manager.startAudit(template, 'store-1');
      manager.setAnswer('c-1', value: 'yes');

      await manager.submitAudit();

      verify(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any())).called(1);
      expect(manager.wasQueuedOffline, isTrue);
    });

    test('TC-11-05: submitAudit sets error string on internal failure', () async {
      when(() => mockOutboxDao.insertSubmissionWithAnswers(any(), any()))
          .thenThrow(Exception('DB Error'));

      await manager.startAudit(template, 'store-1');
      manager.setAnswer('c-1', value: 'yes');

      await manager.submitAudit();

      expect(manager.error, 'Submission failed. Please try again.');
      expect(manager.isSubmitting, isFalse);
    });
  });
}
