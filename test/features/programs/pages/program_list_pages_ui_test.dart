import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/programs/pages/program_list_page.dart';
import 'package:checkly/features/programs/pages/area_campaign_list_page.dart';
import 'package:checkly/features/programs/pages/program_assignment_list_page.dart';
import 'package:checkly/features/programs/services/program_api_service.dart';
import 'package:checkly/features/dashboard/manager/dashboard_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/_shared/widgets/primitives/universal_list_card.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:checkly/features/programs/model/pending_assignment_vm.dart';

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  @override
  Future<void> refreshCapabilities() async {}

  final String? role;
  final Set<String> _caps;
  _StubAuthManager({this.role, Set<String>? capabilities})
    : _caps = capabilities ?? {};

  @override
  ValueListenable<AuthState> get authState => ValueNotifier(
    role != null ? AuthState.authenticated : AuthState.unauthenticated,
  );

  @override
  UserSession? get currentUser => role != null
      ? UserSession(
          userId: '1',
          fullName: 'Test',
          email: 'test@x.com',
          role: role!,
          token: 'tok',
        )
      : null;

  @override
  ValueListenable<Set<String>> get capabilities => ValueNotifier(_caps);

  @override
  Future<void> login(String e, String p) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> tryAutoLogin() async {}
}

class MockProgramApiService extends Mock implements ProgramApiService {}

class MockDashboardManager extends Mock implements DashboardManager {}

class MockPolicyManager extends Mock implements PolicyManager {}

void main() {
  late MockProgramApiService mockProgramApiService;
  late MockDashboardManager mockDashboardManager;
  late MockPolicyManager mockPolicyManager;
  late _StubAuthManager stubAuthManager;

  setUp(() {
    GetIt.I.allowReassignment = true;
    mockProgramApiService = MockProgramApiService();
    mockDashboardManager = MockDashboardManager();
    mockPolicyManager = MockPolicyManager();
    stubAuthManager = _StubAuthManager(
      role: 'admin',
      capabilities: {'programs:create', 'programs:review'},
    );

    GetIt.I.registerSingleton<ProgramApiService>(mockProgramApiService);
    GetIt.I.registerSingleton<DashboardManager>(mockDashboardManager);
    GetIt.I.registerSingleton<AuthManager>(stubAuthManager);
    GetIt.I.registerSingleton<PolicyManager>(mockPolicyManager);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('ProgramListPage UI Tests', () {
    testWidgets('Renders UniversalListCard list when items exist', (
      tester,
    ) async {
      when(() => mockPolicyManager.can(any())).thenReturn(true);
      when(() => mockProgramApiService.getPrograms()).thenAnswer(
        (_) async => {
          'items': [
            {
              'id': 'prog-1',
              'title': 'Safety Program',
              'category': 'safety',
              'status': 'active',
              'totalAssigned': 5,
            },
          ],
        },
      );

      await tester.pumpWidget(const MaterialApp(home: ProgramListPage()));
      await tester.pump(); // Start load
      await tester.pump(); // Finish load

      expect(find.byType(UniversalListCard), findsOneWidget);
      expect(find.text('Safety Program'), findsOneWidget);
      expect(find.text('SAFETY'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('Renders ChecklyEmptyState when list is empty', (tester) async {
      when(() => mockPolicyManager.can(any())).thenReturn(true);
      when(
        () => mockProgramApiService.getPrograms(),
      ).thenAnswer((_) async => {'items': []});

      await tester.pumpWidget(const MaterialApp(home: ProgramListPage()));
      await tester.pump(); // Start load
      await tester.pump(); // Finish load

      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('No Campaigns Found'), findsOneWidget);
    });

    testWidgets('Renders ChecklyEmptyState when API fails', (tester) async {
      when(() => mockPolicyManager.can(any())).thenReturn(true);
      when(
        () => mockProgramApiService.getPrograms(),
      ).thenAnswer((_) async => throw Exception('API error'));

      await tester.pumpWidget(const MaterialApp(home: ProgramListPage()));
      await tester.pump(); // Start load
      await tester.pump(); // Finish load

      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('Unable to Load Campaigns'), findsOneWidget);
    });
  });

  group('AreaCampaignListPage UI Tests', () {
    testWidgets('Renders UniversalListCard and progress bar', (tester) async {
      final campaigns = <AreaCampaignProgressDto>[
        AreaCampaignProgressDto(
          programId: 'camp-1',
          title: 'Q1 Compliance',
          deadline: DateTime.now().add(const Duration(days: 7)),
          totalStores: 10,
          completedStores: 4,
          completionRate: 40,
        ),
      ];
      when(
        () => mockProgramApiService.getAreaCampaignProgress(),
      ).thenAnswer((_) async => campaigns);

      await tester.pumpWidget(const MaterialApp(home: AreaCampaignListPage()));
      await tester.pump(); // Start load
      await tester.pump(); // Finish load

      expect(find.byType(UniversalListCard), findsOneWidget);
      expect(find.text('Q1 Compliance'), findsOneWidget);
      expect(find.text('4 of 10 Stores Completed'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Renders ChecklyEmptyState on error', (tester) async {
      when(
        () => mockProgramApiService.getAreaCampaignProgress(),
      ).thenAnswer((_) async => throw Exception('API error'));

      await tester.pumpWidget(const MaterialApp(home: AreaCampaignListPage()));
      await tester.pump(); // Start load
      await tester.pump(); // Finish load

      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('Unable to Load Campaigns'), findsOneWidget);
    });
  });

  group('ProgramAssignmentListPage UI Tests', () {
    testWidgets('Renders UniversalListCard for pending assignments', (
      tester,
    ) async {
      final vms = [
        PendingAssignmentVm(id: 'assign-1', title: 'Monthly Campaign'),
      ];
      when(
        () => mockDashboardManager.watchActionRequired(),
      ).thenAnswer((_) => Stream.value(vms));

      await tester.pumpWidget(
        const MaterialApp(home: ProgramAssignmentListPage()),
      );
      await tester.pump(); // Start stream load
      await tester.pump(); // Finish stream load

      expect(find.byType(UniversalListCard), findsOneWidget);
      expect(find.text('Monthly Campaign'), findsOneWidget);
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
    });

    testWidgets('Renders ChecklyEmptyState when all caught up', (tester) async {
      when(
        () => mockDashboardManager.watchActionRequired(),
      ).thenAnswer((_) => Stream.value(<PendingAssignmentVm>[]));

      await tester.pumpWidget(
        const MaterialApp(home: ProgramAssignmentListPage()),
      );
      await tester.pump(); // Start stream load
      await tester.pump(); // Finish stream load

      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('All Caught Up!'), findsOneWidget);
    });
  });
}
