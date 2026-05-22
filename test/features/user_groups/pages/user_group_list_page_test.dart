import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:checkly/features/user_groups/pages/user_group_list_page.dart';
import 'package:checkly/features/user_groups/manager/user_group_manager.dart';
import 'package:checkly/features/user_groups/model/user_group_dto.dart';
import 'package:checkly/features/user_groups/widgets/empty_state.dart';
import 'package:checkly/features/user_groups/widgets/error_state.dart';
import 'package:checkly/features/user_groups/widgets/user_group_tile.dart';
import 'package:checkly/features/user_groups/widgets/create_group_sheet.dart';
import 'package:checkly/_shared/services/error_display_service.dart';

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
    di.registerFactory<UserGroupManager>(() => mockManager);
    di.registerFactory<ErrorDisplayService>(() => mockErrorService);

    // Default mocktail setup for manager listeners
    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
    when(() => mockManager.loadGroups()).thenAnswer((_) async {});
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: UserGroupListPage());
  }

  group('UserGroupListPage Widget Tests', () {
    testWidgets('UG-WID-LIST-01: List page loading state', (tester) async {
      when(() => mockManager.isLoading).thenReturn(true);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.groups).thenReturn(<UserGroupDto>[]);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ErrorState), findsNothing);
      expect(find.byType(UserGroupTile), findsNothing);
    });

    testWidgets('UG-WID-LIST-02: List page empty state', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.groups).thenReturn(<UserGroupDto>[]);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);

      // Tapping "Create First Group" opens sheet
      await tester.tap(find.widgetWithText(FilledButton, 'Create First Group'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGroupSheet), findsOneWidget);
    });

    testWidgets('UG-WID-LIST-03: List page error state', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn('Oops! Something went wrong.');
      when(() => mockManager.groups).thenReturn(<UserGroupDto>[]);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Oops! Something went wrong.'), findsOneWidget);

      // Tapping "Retry" calls loadGroups
      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pump();

      verify(
        () => mockManager.loadGroups(),
      ).called(2); // 1 in initState, 1 on tap
    });

    testWidgets('UG-WID-LIST-04: List page success list and FAB click', (
      tester,
    ) async {
      const mockGroups = [
        UserGroupDto(id: '1', name: 'Group 1', description: 'Desc 1'),
        UserGroupDto(id: '2', name: 'Group 2', description: 'Desc 2'),
      ];

      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.groups).thenReturn(mockGroups);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ErrorState), findsNothing);

      expect(find.byType(UserGroupTile), findsNWidgets(2));
      expect(find.text('Group 1'), findsOneWidget);
      expect(find.text('Group 2'), findsOneWidget);

      // Tapping the floating action button "New Group" opens sheet
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(CreateGroupSheet), findsOneWidget);
    });
  });
}
