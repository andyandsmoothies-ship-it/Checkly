import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:checkly/features/audit/pages/audit_form_page.dart';
import 'package:checkly/features/audit/manager/audit_manager.dart';
import 'package:checkly/features/templates/manager/template_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/features/dashboard/manager/dashboard_manager.dart';
import 'package:checkly/features/stores/manager/store_manager.dart';
import 'package:checkly/_shared/services/gps_service.dart';

class MockAuditManager extends Mock implements AuditManager {}

class MockTemplateManager extends Mock implements TemplateManager {}

class MockDashboardManager extends Mock implements DashboardManager {}

class MockStoreManager extends Mock implements StoreManager {}

class MockGpsService extends Mock implements GpsService {}

class FakeTemplateTreeDto extends Fake implements TemplateTreeDto {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTemplateTreeDto());
  });

  late MockAuditManager mockAuditManager;
  late MockTemplateManager mockTemplateManager;
  late MockDashboardManager mockDashboardManager;
  late MockStoreManager mockStoreManager;
  late MockGpsService mockGpsService;

  setUp(() {
    mockAuditManager = MockAuditManager();
    mockTemplateManager = MockTemplateManager();
    mockDashboardManager = MockDashboardManager();
    mockStoreManager = MockStoreManager();
    mockGpsService = MockGpsService();

    final di = GetIt.instance;
    di.reset();
    di.registerSingleton<AuditManager>(mockAuditManager);
    di.registerSingleton<TemplateManager>(mockTemplateManager);
    di.registerSingleton<DashboardManager>(mockDashboardManager);
    di.registerSingleton<StoreManager>(mockStoreManager);
    di.registerSingleton<GpsService>(mockGpsService);

    when(
      () => mockAuditManager.startAudit(
        any(),
        any(),
        targetSubmissionId: any(named: 'targetSubmissionId'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAuditManager.addListener(any())).thenAnswer((_) {});
    when(() => mockAuditManager.removeListener(any())).thenAnswer((_) {});
    when(() => mockAuditManager.hasDraft).thenReturn(false);
    when(() => mockAuditManager.answers).thenReturn({});
    when(() => mockAuditManager.liveScore).thenReturn(100.0);
    when(() => mockAuditManager.sectionScores).thenReturn({});
    when(() => mockAuditManager.storeId).thenReturn('store-1');
    when(() => mockAuditManager.isSubmitting).thenReturn(false);
    when(() => mockAuditManager.wasQueuedOffline).thenReturn(false);
    when(() => mockAuditManager.error).thenReturn(null);
    when(() => mockAuditManager.triggeredRiskIds).thenReturn({});
    when(() => mockAuditManager.draftSavedAt).thenReturn(null);
    when(() => mockAuditManager.submitAudit()).thenAnswer((_) async {});

    when(
      () => mockGpsService.getCurrentPosition(),
    ).thenAnswer((_) async => null);
  });

  testWidgets(
    'AuditFormPage._onSubmit calculates missingRequired based on individual and global config',
    (tester) async {
      // 1. Arrange: Global confirm is OFF, but one criterion is individually required.
      final template = TemplateTreeDto(
        id: 't-1',
        title: 'Test Template',
        type: 'qc',
        version: 1,
        isActive: true,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        groups: [
          GroupDto(
            id: 'g-1',
            title: 'Group 1',
            orderIndex: 0,
            criteria: [
              CriterionDto(
                id: 'c-1',
                label: 'Required Criterion',
                inputType: 'text',
                orderIndex: 0,
                isCcp: false,
                isRisk: false,
                metadata: jsonEncode({
                  'isRequired': true,
                }), // Individually required
              ),
            ],
            children: [],
          ),
        ],
        scoringLogicConfig: jsonEncode({
          'confirmCorrect': false,
        }), // Global confirm OFF
      );

      when(
        () => mockTemplateManager.loadTemplateTree(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTemplateManager.selectedTemplate,
      ).thenReturn(ValueNotifier(template));
      when(() => mockAuditManager.template).thenReturn(template);

      await tester.pumpWidget(
        MaterialApp(
          home: const AuditFormPage(templateId: 't-1', storeId: 'store-1'),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Act: Tap submit button
      final submitButton = find.text('Submit');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // 3. Assert:
      // The submission should be blocked because c-1 is required but unanswered.
      // Expected behavior: submitAudit() is NEVER called.
      // Expected behavior: A snackbar shows "1 required criteria still need review".
      verifyNever(() => mockAuditManager.submitAudit());

      // We also expect the confirmation dialog ("Submit Audit?") NOT to appear.
      // If it appears, that means the gate was bypassed.
      expect(find.text('Submit Audit?'), findsNothing);
    },
  );
}
