// Test Plan:
// Covers TC-PBAC-04 from the PBAC Phase A implementation plan.
// Spec: AdminAuditManager.loadScheduleData() must call the PBAC backend filter
// endpoint (searchUsersByCapability('submissions:create')) to build the auditor
// list, NOT hardcoded role-string logic on the frontend.
//
// Input Lineage:
// C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md
//
// Why these tests will fail (RED phase):
// AdminAuditManager currently calls searchUsersByCapability('submissions:create'),
// but TC-PBAC-04 specifies the auditor list is filtered by 'submissions:create'.
// Tests will pinpoint the exact capability string the Builder must switch to.
//
// Additional coverage:
// Unit tests prove that scheduleData.allAuditors is populated DIRECTLY from the
// API result, with no additional frontend `role == 'auditor'` string filtering.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/manager/admin_audit_manager.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/features/stores/model/store_dto.dart';
import 'package:checkly/features/templates/services/template_api_service.dart';
import 'package:checkly/features/templates/models/template_dto.dart';
import 'package:checkly/features/auth/model/user_session.dart';

class MockAdminApiService extends Mock implements AdminApiService {}

class MockStoreApiService extends Mock implements StoreApiService {}

class MockTemplateApiService extends Mock implements TemplateApiService {}

class MockSubmissionApiService extends Mock implements SubmissionApiService {}

class MockAuthManager extends Mock implements AuthManager {}

// Fixture helpers — produce minimal valid DTO instances
TemplateDto _template({String id = 'tpl_1', String title = 'Template A'}) =>
    TemplateDto(
      id: id,
      title: title,
      type: 'standard',
      version: 1,
      isActive: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

StoreDto _store({String id = 'store_1', String name = 'Store A'}) =>
    StoreDto(id: id, name: name, createdAt: DateTime(2024));

void main() {
  late MockAdminApiService mockAdminApi;
  late MockStoreApiService mockStoreApi;
  late MockTemplateApiService mockTemplateApi;
  late MockSubmissionApiService mockSubmissionApi;
  late MockAuthManager mockAuth;
  late AdminAuditManager sut; // System Under Test

  setUp(() {
    mockAdminApi = MockAdminApiService();
    mockStoreApi = MockStoreApiService();
    mockTemplateApi = MockTemplateApiService();
    mockSubmissionApi = MockSubmissionApiService();
    mockAuth = MockAuthManager();

    // Default: an SM user (no area scoping)
    when(() => mockAuth.currentUser).thenReturn(
      const UserSession(
        userId: 'u1',
        email: 'sm@test.com',
        role: 'store_manager',
        token: 'tok',
      ),
    );

    when(
      () => mockTemplateApi.getTemplates(),
    ).thenAnswer((_) async => [_template()]);
    when(() => mockStoreApi.getStores()).thenAnswer((_) async => [_store()]);

    sut = AdminAuditManager(
      adminApi: mockAdminApi,
      storeApi: mockStoreApi,
      templateApi: mockTemplateApi,
      submissionApi: mockSubmissionApi,
      auth: mockAuth,
    );
  });

  // ── TC-PBAC-04: Core Contract — backend PBAC filter is called ─────────────

  test(
    'TC-PBAC-04a: LoadScheduleData_CallsBackend_WithSubmissionsCreateCapability',
    () async {
      // Arrange: stub the PBAC endpoint with the CORRECT capability string.
      // If the Builder switches the call to 'submissions:create', this PASSES.
      // If the code still calls 'submissions:execute', verify() will FAIL.
      when(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'aud_1',
            'fullName': 'Jane Auditor',
            'role': 'auditor',
            'areaId': null,
          },
        ],
      );

      // Act
      await sut.loadScheduleData();

      // Assert: the manager MUST call the backend with 'submissions:create'
      verify(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).called(1);
    },
  );

  test(
    'TC-PBAC-04b: LoadScheduleData_DoesNotCallBackend_WithSubmissionsExecuteCapability',
    () async {
      // Arrange: only stub 'submissions:create'. If production code calls
      // 'submissions:execute', the missing stub will throw a MissingStubError.
      when(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).thenAnswer((_) async => []);

      // Act
      await sut.loadScheduleData();

      // Assert: the OLD capability string must NOT be used
      verifyNever(
        () => mockAdminApi.searchUsersByCapability('submissions:execute'),
      );
    },
  );

  // ── TC-PBAC-04: Happy Path — auditor list populated from API ──────────────

  test(
    'TC-PBAC-04c: LoadScheduleData_PopulatesAllAuditors_DirectlyFromApiResult',
    () async {
      // Arrange
      final apiAuditors = [
        {
          'id': 'aud_1',
          'fullName': 'Jane Auditor',
          'role': 'auditor',
          'areaId': null,
        },
        {
          'id': 'am_1',
          'fullName': 'Bob Manager',
          'role': 'area_manager',
          'areaId': 'area_1',
        },
      ];
      when(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).thenAnswer((_) async => apiAuditors);

      // Act
      await sut.loadScheduleData();

      // Assert: both users from the API must be in allAuditors (no frontend filtering)
      expect(sut.scheduleData, isNotNull);
      final auditors = sut.scheduleData!.allAuditors;
      expect(
        auditors.map((u) => u['id']).toList(),
        containsAll(['aud_1', 'am_1']),
        reason:
            'allAuditors must include ALL users returned by the PBAC API — '
            'no additional role-string filtering on the frontend',
      );
    },
  );

  // ── TC-PBAC-04: Empty State — API returns no eligible users ───────────────

  test(
    'TC-PBAC-04d: LoadScheduleData_EmptyApiResult_AllAuditorsIsEmpty',
    () async {
      // Arrange: backend returns empty list (no users have submissions:execute)
      when(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).thenAnswer((_) async => []);

      // Act
      await sut.loadScheduleData();

      // Assert: allAuditors is empty — no fallback role-string filter adds users
      expect(sut.scheduleData, isNotNull);
      expect(
        sut.scheduleData!.allAuditors,
        isEmpty,
        reason:
            'If the API returns no eligible users, auditor list must be empty',
      );
    },
  );

  // ── TC-PBAC-04: Error State — API failure sets scheduleError ──────────────

  test('TC-PBAC-04e: LoadScheduleData_ApiThrows_SetsScheduleError', () async {
    // Arrange: the PBAC user endpoint throws (network failure scenario)
    when(
      () => mockAdminApi.searchUsersByCapability('submissions:create'),
    ).thenThrow(Exception('Network timeout'));

    // Act
    await sut.loadScheduleData();

    // Assert: scheduleError is set, scheduleData remains null
    expect(
      sut.scheduleError,
      isNotNull,
      reason: 'A backend failure must populate scheduleError',
    );
    expect(
      sut.scheduleData,
      isNull,
      reason: 'scheduleData must remain null when loading failed',
    );
  });

  // ── TC-PBAC-04: Completion State — loading flag is cleared ────────────────

  test(
    'TC-PBAC-04f: LoadScheduleData_AfterCompletion_SetsIsScheduleLoadingFalse',
    () async {
      // Arrange
      when(
        () => mockAdminApi.searchUsersByCapability('submissions:create'),
      ).thenAnswer((_) async => []);

      // Act
      await sut.loadScheduleData();

      // Assert: loading flag must be cleared after completion
      expect(
        sut.isScheduleLoading,
        isFalse,
        reason:
            'isScheduleLoading must be false after loadScheduleData completes',
      );
    },
  );
}
