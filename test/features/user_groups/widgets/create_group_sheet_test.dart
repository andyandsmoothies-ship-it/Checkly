import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/user_groups/widgets/create_group_sheet.dart';
import 'package:checkly/features/user_groups/manager/user_group_manager.dart';
import 'package:checkly/_shared/services/error_display_service.dart';
import 'package:checkly/_shared/exceptions/app_error.dart';
import 'package:checkly/_shared/widgets/primitives/bubbly_button.dart';

class MockUserGroupManager extends Mock implements UserGroupManager {}

class MockErrorDisplayService extends Mock implements ErrorDisplayService {}

void main() {
  late MockUserGroupManager mockManager;
  late MockErrorDisplayService mockErrorService;

  setUp(() {
    mockManager = MockUserGroupManager();
    mockErrorService = MockErrorDisplayService();

    final di = GetIt.instance;
    di.pushNewScope();
    di.registerFactory<ErrorDisplayService>(() => mockErrorService);

    // Default stub for error so we don't crash
    when(() => mockManager.error).thenReturn(null);
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateGroupSheet(manager: mockManager),
                );
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ),
    );
  }

  group('CreateGroupSheet Widget Tests', () {
    testWidgets('UG-WID-CREATE-01: Form renders correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Create User Group'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Group Name *'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        findsOneWidget,
      );
      expect(find.byType(BubblyButton), findsOneWidget);
    });

    testWidgets('UG-WID-CREATE-VAL-01: Validation empty name', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Submit form directly (empty fields)
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      expect(find.text('Group name is required.'), findsOneWidget);
      verifyNever(() => mockManager.createGroup(any(), any()));
    });

    testWidgets('UG-WID-CREATE-VAL-02: Validation name length > 200', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Set text to > 200 characters directly on the controller to bypass length limiter
      final nameFieldFinder = find.byType(TextFormField).first;
      final TextFormField nameField = tester.widget<TextFormField>(
        nameFieldFinder,
      );
      nameField.controller!.text = 'a' * 201;
      await tester.pump();

      // Submit form
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      expect(find.text('Name must not exceed 200 characters.'), findsOneWidget);
      verifyNever(() => mockManager.createGroup(any(), any()));
    });

    testWidgets('UG-WID-CREATE-02: Form submit success flow', (tester) async {
      when(
        () => mockManager.createGroup('New Team', 'Desc'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid name and description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name *'),
        'New Team',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'),
        'Desc',
      );
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify createGroup called
      verify(() => mockManager.createGroup('New Team', 'Desc')).called(1);

      // Verify sheet popped (CreateGroupSheet is no longer visible)
      expect(find.byType(CreateGroupSheet), findsNothing);

      // Verify SnackBar shown
      expect(find.text('Group "New Team" created.'), findsOneWidget);
    });

    testWidgets('UG-WID-CREATE-03: Form submit failure flow', (tester) async {
      when(
        () => mockManager.createGroup('Fail Team', null),
      ).thenAnswer((_) async => false);
      when(() => mockManager.error).thenReturn('Custom API Error');

      // register Fallback value for AppError
      registerFallbackValue(AppError(code: 'test', message: 'test'));

      await tester.pumpWidget(buildTestWidget());

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid name, no description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name *'),
        'Fail Team',
      );
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify createGroup called
      verify(() => mockManager.createGroup('Fail Team', null)).called(1);

      // Verify sheet NOT popped
      expect(find.byType(CreateGroupSheet), findsOneWidget);

      // Verify error display service called with custom error
      final capturedError =
          verify(() => mockErrorService.show(captureAny())).captured.single
              as AppError;
      expect(capturedError.message, equals('Custom API Error'));
    });
  });
}
