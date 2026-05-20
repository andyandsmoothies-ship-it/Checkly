import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/admin/widgets/user_create_sheet.dart';

void main() {
  group('Slice 6 - Phase 2 UI: AM Store Transfer ATDD', () {
    testWidgets('Toggle "Show assigned stores" removes assignableAs filter', (
      WidgetTester tester,
    ) async {
      String? capturedAssignableAs = 'not_called';
      int loadCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCreateSheet(
              loadStores: ({String? assignableAs, String? exceptUser}) async {
                capturedAssignableAs = assignableAs;
                loadCount++;
                return [
                  {
                    'id': 'store_1',
                    'name': 'Store 1',
                    'managerName': 'Manager 1',
                  },
                ];
              },
              onCreate:
                  ({
                    required email,
                    required password,
                    required fullName,
                    required role,
                    storeId,
                    assignedStoreIds,
                    bool? forceReassign,
                  }) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Change role to area_manager -> triggers initial loadStores(assignableAs: 'area_manager')
      await tester.tap(find.text('Auditor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Area Manager').last);
      await tester.pumpAndSettle();

      expect(loadCount, 1, reason: 'Should load stores initially');
      expect(
        capturedAssignableAs,
        'area_manager',
        reason: 'Initial load should filter for vacant stores',
      );

      // Toggle "Show assigned stores" ON
      final switchFinder = find.byType(SwitchListTile);
      expect(
        switchFinder,
        findsOneWidget,
        reason: 'Toggle should exist for Area Manager',
      );

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(loadCount, 2, reason: 'Should reload stores after toggle');
      expect(
        capturedAssignableAs,
        isNull,
        reason:
            'Toggled ON should remove the assignableAs filter to show taken stores',
      );
    });

    testWidgets('409 Conflict on AM store triggers Transfer Dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCreateSheet(
              loadStores: ({String? assignableAs, String? exceptUser}) async {
                return [
                  {'id': 'store_1', 'name': 'Store 1'},
                ];
              },
              onCreate:
                  ({
                    required email,
                    required password,
                    required fullName,
                    required role,
                    storeId,
                    assignedStoreIds,
                    bool? forceReassign,
                  }) async {
                    // Simulate 409 Conflict from backend
                    throw DioException(
                      requestOptions: RequestOptions(path: ''),
                      response: Response(
                        requestOptions: RequestOptions(path: ''),
                        statusCode: 409,
                        data: {
                          'error': 'Store already has an area manager assigned',
                          'existingManagerName': 'Old AM',
                          'storeName': 'Store 1',
                        },
                      ),
                    );
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
      await tester.tap(find.text('Store 1').last);
      await tester.pumpAndSettle();

      // Submit
      final createUserBtn = find.text('Create User');
      await tester.ensureVisible(createUserBtn);
      await tester.tap(createUserBtn);
      await tester.pumpAndSettle();

      // Transfer Dialog should appear
      expect(
        find.text('Transfer Store Assignment?'),
        findsOneWidget,
        reason: '409 should pop Transfer Dialog',
      );
      expect(
        find.textContaining('Old AM'),
        findsOneWidget,
        reason: 'Dialog should show existing manager name',
      );
    });

    testWidgets('Confirming Transfer submits with forceReassign = true', (
      WidgetTester tester,
    ) async {
      bool? capturedForceReassign;
      int createCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCreateSheet(
              loadStores: ({String? assignableAs, String? exceptUser}) async {
                return [
                  {'id': 'store_1', 'name': 'Store 1'},
                ];
              },
              onCreate:
                  ({
                    required email,
                    required password,
                    required fullName,
                    required role,
                    storeId,
                    assignedStoreIds,
                    bool? forceReassign,
                  }) async {
                    createCallCount++;
                    capturedForceReassign = forceReassign;

                    if (createCallCount == 1) {
                      // First call throws 409
                      throw DioException(
                        requestOptions: RequestOptions(path: ''),
                        response: Response(
                          requestOptions: RequestOptions(path: ''),
                          statusCode: 409,
                          data: {
                            'error':
                                'Store already has an area manager assigned',
                            'existingManagerName': 'Old AM',
                            'storeName': 'Store 1',
                          },
                        ),
                      );
                    }
                    // Second call (confirmation) succeeds
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
      await tester.tap(find.text('Store 1').last);
      await tester.pumpAndSettle();

      // Submit -> throws 409 -> shows dialog
      final createUserBtn1 = find.text('Create User');
      await tester.ensureVisible(createUserBtn1);
      await tester.tap(createUserBtn1);
      await tester.pumpAndSettle();

      // Tap Confirm
      await tester.tap(find.text('Confirm Transfer'));
      await tester.pumpAndSettle();

      expect(
        createCallCount,
        2,
        reason: 'Should call API twice: initial + confirmation',
      );
      expect(
        capturedForceReassign,
        isTrue,
        reason: 'Second call must have forceReassign=true',
      );
    });

    testWidgets('Cancelling Transfer aborts the operation', (
      WidgetTester tester,
    ) async {
      int createCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCreateSheet(
              loadStores: ({String? assignableAs, String? exceptUser}) async {
                return [
                  {'id': 'store_1', 'name': 'Store 1'},
                ];
              },
              onCreate:
                  ({
                    required email,
                    required password,
                    required fullName,
                    required role,
                    storeId,
                    assignedStoreIds,
                    bool? forceReassign,
                  }) async {
                    createCallCount++;
                    throw DioException(
                      requestOptions: RequestOptions(path: ''),
                      response: Response(
                        requestOptions: RequestOptions(path: ''),
                        statusCode: 409,
                        data: {
                          'error': 'Store already has an area manager assigned',
                          'existingManagerName': 'Old AM',
                          'storeName': 'Store 1',
                        },
                      ),
                    );
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
      await tester.tap(find.text('Store 1').last);
      await tester.pumpAndSettle();

      // Submit -> throws 409 -> shows dialog
      final createUserBtn2 = find.text('Create User');
      await tester.ensureVisible(createUserBtn2);
      await tester.tap(createUserBtn2);
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(createCallCount, 1, reason: 'Should NOT call API a second time');
      expect(
        find.byType(UserCreateSheet),
        findsOneWidget,
        reason: 'Sheet should remain open after cancel',
      );
    });
  });
}
