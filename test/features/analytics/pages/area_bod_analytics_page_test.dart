import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/features/analytics/pages/area_bod_analytics_page.dart';
import 'package:checkly/features/analytics/manager/area_bod_manager.dart';
import 'package:checkly/features/analytics/manager/area_bod_data.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart' show BodAgingBucket, ApDetailEntry, StoreBodSummary, RecentAuditEntry;
import 'package:checkly/features/analytics/widgets/area_bod_region_filter_sheet.dart';
import 'package:checkly/features/analytics/widgets/area_bod_dashboard_body.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/_shared/router/auth_redirect.dart';

class MockAreaBodManager extends Mock implements AreaBodManager {}

class MockPolicyManager extends Mock implements PolicyManager {}

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  final Set<String> _caps;
  _StubAuthManager({required Set<String> capabilities}) : _caps = capabilities;

  @override
  ValueListenable<AuthState> get authState =>
      ValueNotifier(AuthState.authenticated);
  @override
  UserSession? get currentUser => const UserSession(
    userId: '1',
    fullName: 'Area Manager User',
    email: 'areamanager@checkly.com',
    role: 'area_manager',
    token: 'area-token',
  );
  @override
  ValueListenable<Set<String>> get capabilities => ValueNotifier(_caps);

  @override
  Future<void> refreshCapabilities() async {}
  @override
  Future<void> login(String e, String p) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> tryAutoLogin() async {}
}

class MockBuildContext extends Fake implements BuildContext {}

class MockGoRouterState extends Fake implements GoRouterState {
  final String _matchedLocation;
  MockGoRouterState(this._matchedLocation);

  @override
  String get matchedLocation => _matchedLocation;
}

void main() {
  setUpAll(() {
    registerFallbackValue(BodAgingBucket.all);
  });

  late MockAreaBodManager mockManager;

  setUp(() {
    mockManager = MockAreaBodManager();
    final di = GetIt.instance;
    di.pushNewScope();
    di.registerFactory<AreaBodManager>(() => mockManager);

    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
    when(() => mockManager.loadReport()).thenAnswer((_) async {});
    when(() => mockManager.isLiveMode).thenReturn(false);
    when(() => mockManager.activeProvince).thenReturn(null);
    when(() => mockManager.activeDistrict).thenReturn(null);
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: AreaBodAnalyticsPage(),
    );
  }

  final successReportComplete = AreaBodResponse(
    isLiveData: false,
    kpis: AreaBodKpis(
      totalAudits: 450,
      avgScore: 84.5,
      completionRate: 92.4,
      openActionPlans: 15,
      overdueActionPlans: 5,
      activeStores: 12,
      totalAuditors: 4,
      avgTtrDays: 5.5,
    ),
    trend: [],
    topStores: [],
    bottomStores: [],
    weaknesses: [],
    actionPlanAging: const [],
    auditorProductivity: [],
    allowedActions: ['refresh'],
  );

  group('AreaBodAnalyticsPage Routing & Guard Tests', () {
    void arrangeCapabilities(Set<String> caps) {
      final auth = _StubAuthManager(capabilities: caps);
      if (GetIt.I.isRegistered<AuthManager>()) {
        GetIt.I.unregister<AuthManager>();
      }
      if (GetIt.I.isRegistered<PolicyManager>()) {
        GetIt.I.unregister<PolicyManager>();
      }
      GetIt.I.registerSingleton<AuthManager>(auth);
      GetIt.I.registerSingleton<PolicyManager>(PolicyManager(auth: auth));
    }

    test(
      'TC-AREA-BOD-ROUTING-01: Gated route blocks unauthorized and allows authorized',
      () {
        // 1. Block unauthorized role missing 'analytics:area' capability
        arrangeCapabilities({'submissions:create'});
        final blockResult = authRedirect(
          MockBuildContext(),
          MockGoRouterState('/analytics/area'),
        );
        expect(blockResult, equals('/home'));

        // 2. Allow authorized role containing 'analytics:area' and 'analytics:view' capabilities
        arrangeCapabilities({'analytics:area', 'analytics:view'});
        final allowResult = authRedirect(
          MockBuildContext(),
          MockGoRouterState('/analytics/area'),
        );
        expect(allowResult, isNull);
      },
    );
  });

  group('AreaBodAnalyticsPage Widget States & Action Tests', () {
    testWidgets(
      'TC-AREA-BOD-UI-01: Displays loading state accurately with custom text',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(true);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Fetching area boardroom dashboard...'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-AREA-BOD-UI-02: Offline state renders Connection Required ChecklyEmptyState with Try Again',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(true);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ChecklyEmptyState), findsOneWidget);
        expect(find.text('Connection Required'), findsOneWidget);
        expect(
          find.textContaining('Area BOD Analytics requires an active internet connection'),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Try Again'), findsOneWidget);

        when(() => mockManager.refreshReport()).thenAnswer((_) async {});
        await tester.tap(find.widgetWithText(OutlinedButton, 'Try Again'));
        await tester.pump();

        verify(() => mockManager.refreshReport()).called(1);
      },
    );

    testWidgets(
      'TC-AREA-BOD-UI-03: Empty state renders Area Dashboard Empty ChecklyEmptyState with Trigger Recomputation',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(true);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ChecklyEmptyState), findsOneWidget);
        expect(find.text('Area Dashboard Empty'), findsOneWidget);
        expect(
          find.textContaining('No pre-computed report is available yet.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Trigger Recomputation'), findsOneWidget);

        when(() => mockManager.refreshReport()).thenAnswer((_) async {});
        await tester.tap(find.widgetWithText(FilledButton, 'Trigger Recomputation'));
        await tester.pump();

        verify(() => mockManager.refreshReport()).called(1);
      },
    );

    testWidgets(
      'TC-AREA-BOD-UI-04: System Error renders System Error ChecklyEmptyState with Retry',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn('Unhandled generic timeout');
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ChecklyEmptyState), findsOneWidget);
        expect(find.text('System Error'), findsOneWidget);
        expect(
          find.textContaining('An unexpected system error occurred while retrieving area dashboard.'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

        when(() => mockManager.loadReport()).thenAnswer((_) async {});
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await tester.pump();

        verify(() => mockManager.loadReport()).called(2);
      },
    );

    testWidgets(
      'TC-AREA-BOD-UI-05: Success state renders AreaBodDashboardBody containing all 6 premium panels',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(successReportComplete);

        await tester.pumpWidget(buildTestWidget());

        // We expect AreaBodDashboardBody to be loaded
        expect(find.byType(AreaBodDashboardBody), findsOneWidget);

        // Verify premium StrokeCards
        expect(find.byType(StrokeCard), findsNWidgets(6));
      },
    );
  });
}
