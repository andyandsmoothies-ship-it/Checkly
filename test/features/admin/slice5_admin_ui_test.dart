import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/widgets/user_edit_sheet.dart';
import 'package:checkly/features/admin/widgets/user_create_sheet.dart';
import 'package:checkly/features/admin/widgets/schedule_audit_form.dart';
import 'package:checkly/features/admin/manager/admin_audit_manager.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';

class MockAdminAuditManager extends Mock implements AdminAuditManager {}

class MockSubmissionApiService extends Mock implements SubmissionApiService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('Slice 5 - TC-5.1 & TC-5.2: Store Assignments for AM', () {
    testWidgets('UserEditSheet sends assignedStoreIds for area_manager', (
      WidgetTester tester,
    ) async {
      List<String>? capturedStoreIds;
      bool saveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserEditSheet(
              user: const {'id': 'u1', 'role': 'auditor', 'fullName': 'Test'},
              loadStores: ({String? assignableAs, String? exceptUser}) async =>
                  [
                    {
                      'id': 'store_1',
                      'name': 'Store 1',
                      'managerName': 'Manager 1',
                    },
                  ],
              onSave:
                  ({
                    required userId,
                    fullName,
                    role,
                    storeId,
                    assignedStoreIds,
                  }) async {
                    saveCalled = true;
                    capturedStoreIds = assignedStoreIds;
                  },
              onResetPassword: (a, b, c) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change role to area_manager
      await tester.tap(find.text('Auditor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Area Manager').last);
      await tester.pumpAndSettle();

      // Select store
      await tester.tap(find.text('Store 1').last);
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);
      expect(capturedStoreIds, ['store_1']);
    });

    testWidgets('UserCreateSheet sends assignedStoreIds for area_manager', (
      WidgetTester tester,
    ) async {
      List<String>? capturedStoreIds;
      bool createCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCreateSheet(
              loadStores: ({String? assignableAs, String? exceptUser}) async =>
                  [
                    {
                      'id': 'store_2',
                      'name': 'Store 2',
                      'managerName': 'Manager 2',
                    },
                  ],
              onCreate:
                  ({
                    required email,
                    required password,
                    required fullName,
                    required role,
                    storeId,
                    assignedStoreIds,
                    forceReassign,
                  }) async {
                    createCalled = true;
                    capturedStoreIds = assignedStoreIds;
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill required fields
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'Password123!');

      // Change role to area_manager
      await tester.tap(find.text('Auditor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Area Manager').last);
      await tester.pumpAndSettle();

      // Select store
      await tester.tap(find.text('Store 2').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Create User'));
      await tester.tap(find.text('Create User'));
      await tester.pumpAndSettle();

      expect(createCalled, isTrue);
      expect(capturedStoreIds, ['store_2']);
    });
  });

  group('Slice 5 - TC-5.3, TC-5.4, TC-5.5: ScheduleAuditForm AM Filtering', () {
    late MockAdminAuditManager mockManager;
    late MockSubmissionApiService mockSubmitService;

    setUp(() {
      mockManager = MockAdminAuditManager();
      mockSubmitService = MockSubmissionApiService();
      GetIt.instance.registerSingleton<AdminAuditManager>(mockManager);
      GetIt.instance.registerSingleton<SubmissionApiService>(mockSubmitService);

      when(() => mockManager.scheduleError).thenReturn(null);
      // We don't want the real loadScheduleData to do anything, we just mock the data.
      when(() => mockManager.loadScheduleData()).thenAnswer((_) async {});
    });

    testWidgets('TC-5.3: Selected store filters AM list by assignedStoreIds', (
      WidgetTester tester,
    ) async {
      when(() => mockManager.scheduleData).thenReturn(
        ScheduleFormData(
          templates: [
            {'id': 't1', 'title': 'Template 1'},
          ],
          allStores: [
            {'id': 'store_1', 'name': 'Store A', 'areaId': 'legacy_area_1'},
            {'id': 'store_2', 'name': 'Store B', 'areaId': 'legacy_area_2'},
          ],
          allAuditors: [
            // This AM is assigned to store_1 but has legacy areaId = legacy_area_2
            {
              'id': 'am_1',
              'fullName': 'Area Manager 1',
              'role': 'area_manager',
              'assignedStoreIds': ['store_1'],
              'areaId': 'legacy_area_2',
            },
          ],
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScheduleAuditForm())),
      );
      await tester.pumpAndSettle();

      // Select Store 1
      await tester.tap(find.text('Select a store'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Store A').last);
      await tester.pumpAndSettle();

      // Open Auditor dropdown
      await tester.tap(find.text('Assign an auditor'));
      await tester.pumpAndSettle();

      // Area Manager 1 should be visible because store_1 is in assignedStoreIds,
      // EVEN THOUGH their legacy areaId is legacy_area_2.
      expect(
        find.text('Area Manager 1'),
        findsOneWidget,
        reason: 'AM should be eligible via assignedStoreIds',
      );
    });

    testWidgets(
      'TC-5.4: Auditor list excludes AM if they are not assigned to selected store',
      (WidgetTester tester) async {
        when(() => mockManager.scheduleData).thenReturn(
          ScheduleFormData(
            templates: [
              {'id': 't1', 'title': 'Template 1'},
            ],
            allStores: [
              {'id': 'store_1', 'name': 'Store A', 'areaId': 'legacy_area_1'},
              {'id': 'store_2', 'name': 'Store B', 'areaId': 'legacy_area_2'},
            ],
            allAuditors: [
              {
                'id': 'am_1',
                'fullName': 'Area Manager 1',
                'role': 'area_manager',
                'assignedStoreIds': ['store_1'], // Only eligible for Store A
                'areaId': 'legacy_area_1',
              },
            ],
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ScheduleAuditForm())),
        );
        await tester.pumpAndSettle();

        // Select Store B (AM is NOT assigned here)
        await tester.tap(find.text('Select a store'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Store B').last);
        await tester.pumpAndSettle();

        // Open Auditor dropdown
        await tester.tap(find.text('Assign an auditor'));
        await tester.pumpAndSettle();

        // Area Manager 1 should NOT be in the dropdown
        expect(
          find.text('Area Manager 1'),
          findsNothing,
          reason: 'Auditor should be hidden if ineligible for the store',
        );
      },
    );

    testWidgets(
      'TC-5.5: Non-AM auditors keep prior fallback behavior (no assignment list required)',
      (WidgetTester tester) async {
        when(() => mockManager.scheduleData).thenReturn(
          ScheduleFormData(
            templates: [
              {'id': 't1', 'title': 'Template 1'},
            ],
            allStores: [
              {'id': 'store_1', 'name': 'Store A', 'areaId': 'legacy_area_1'},
            ],
            allAuditors: [
              {
                'id': 'aud_1',
                'fullName': 'Regular Auditor',
                'role': 'auditor',
                // No assignedStoreIds, areaId is null -> floating auditor
                'areaId': null,
              },
            ],
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ScheduleAuditForm())),
        );
        await tester.pumpAndSettle();

        // Select Store 1
        await tester.tap(find.text('Select a store'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Store A').last);
        await tester.pumpAndSettle();

        // Open Auditor dropdown
        await tester.tap(find.text('Assign an auditor'));
        await tester.pumpAndSettle();

        // Regular auditor should still be eligible
        expect(
          find.text('Regular Auditor'),
          findsOneWidget,
          reason: 'Regular auditor without area should be globally eligible',
        );
      },
    );
  });
}
