import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/_shared/services/geocoding_service.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/features/admin/widgets/user_create_sheet.dart';
import 'package:checkly/features/admin/widgets/user_edit_sheet.dart';
import 'package:checkly/features/admin/pages/widgets/risk_form_sheet.dart';
import 'package:checkly/features/admin/pages/widgets/store_form_sheet.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/features/action_plans/widgets/submit_evidence_sheet.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/templates/pages/template_builder_page.dart';
import 'package:checkly/features/templates/manager/template_manager.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

class MockAdminApiService extends Mock implements AdminApiService {}
class MockErrorDisplayService extends Mock implements ErrorDisplayService {}
class MockStoreApiService extends Mock implements StoreApiService {}
class MockGeocodingService extends Mock implements GeocodingService {}
class MockActionPlanManager extends Mock implements ActionPlanManager {}
class MockTemplateManager extends Mock implements TemplateManager {}

void main() {
  late MockAdminApiService mockAdminApi;
  late MockErrorDisplayService mockErrorDisplay;
  late MockStoreApiService mockStoreApi;
  late MockGeocodingService mockGeocoding;
  late MockTemplateManager mockTemplateManager;

  setUp(() {
    mockAdminApi = MockAdminApiService();
    mockErrorDisplay = MockErrorDisplayService();
    mockStoreApi = MockStoreApiService();
    mockGeocoding = MockGeocodingService();
    mockTemplateManager = MockTemplateManager();

    final di = GetIt.instance;
    di.registerSingleton<AdminApiService>(mockAdminApi);
    di.registerSingleton<ErrorDisplayService>(mockErrorDisplay);
    di.registerSingleton<StoreApiService>(mockStoreApi);
    di.registerSingleton<GeocodingService>(mockGeocoding);
    di.registerSingleton<TemplateManager>(mockTemplateManager);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Future<void> showSheet(WidgetTester tester, Widget sheet) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            // Safe fallbacks are used if null
          ],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => sheet,
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  group('UnsavedChangesGuard Sheet Integration Tests', () {
    testWidgets('UserCreateSheet pops cleanly on successful create', (tester) async {
      await showSheet(
        tester,
        UserCreateSheet(
          loadStores: ({String? assignableAs, String? exceptUser}) async => [],
          onCreate: ({
            required email,
            required password,
            required fullName,
            required role,
            storeId,
            assignedStoreIds,
            bool? forceReassign,
          }) async {
            // Success call
          },
        ),
      );

      // Fill in required fields
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'Password123!');
      await tester.pumpAndSettle();

      // Tap Create User
      final createBtn = find.text('Create User');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      
      // Wait for the async onCreate callback and the post-frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify the sheet was popped successfully and no discard dialog was shown
      expect(find.byType(UserCreateSheet), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('UserEditSheet triggers onSave cleanly and pops', (tester) async {
      bool onSaveCalled = false;

      await showSheet(
        tester,
        UserEditSheet(
          user: const {
            'id': 'user_123',
            'fullName': 'Jane Doe',
            'email': 'jane@example.com',
            'role': 'auditor',
          },
          loadStores: ({String? assignableAs, String? exceptUser}) async => [],
          onSave: ({
            required userId,
            fullName,
            role,
            storeId,
            assignedStoreIds,
          }) async {
            onSaveCalled = true;
          },
          onResetPassword: (sheetCtx, userId, userName) async {},
        ),
      );

      // Edit field to make it dirty
      await tester.enterText(find.byType(TextField).first, 'Jane Doe Edited');
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      
      // Wait for callback and post-frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      expect(onSaveCalled, isTrue);
      // In the real app, user_management_page.dart's _saveUser performs the actual pop, 
      // but here we verify no discard changes dialog was triggered.
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('RiskFormSheet pops cleanly on successful create risk', (tester) async {
      when(() => mockAdminApi.createGlobalRisk(
            label: any(named: 'label'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await showSheet(
        tester,
        RiskFormSheet(
          onSaved: () {},
        ),
      );

      // Fill Risk Label
      await tester.enterText(find.byType(TextField).first, 'New Risk Label');
      await tester.pumpAndSettle();

      // Tap Create Risk
      final createBtn = find.text('Create Risk');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);

      // Wait for async request and post-frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify risk sheet popped cleanly and no discard dialog is shown
      expect(find.byType(RiskFormSheet), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('RiskFormSheet pops cleanly on successful edit risk', (tester) async {
      when(() => mockAdminApi.updateGlobalRisk(
            any(),
            label: any(named: 'label'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await showSheet(
        tester,
        RiskFormSheet(
          risk: const {
            'id': 'risk_123',
            'label': 'Existing Risk',
            'description': 'Description',
            'isActive': true,
          },
          onSaved: () {},
        ),
      );

      // Edit field to make dirty
      await tester.enterText(find.byType(TextField).first, 'Existing Risk Edited');
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);

      // Wait for async request and post-frame callback
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify risk sheet popped cleanly and no discard dialog is shown
      expect(find.byType(RiskFormSheet), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });
  });
}
