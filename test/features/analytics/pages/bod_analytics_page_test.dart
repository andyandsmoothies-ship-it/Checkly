import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/features/analytics/pages/bod_analytics_page.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/auth/model/auth_state.dart';
import 'package:checkly/features/auth/model/user_session.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import 'package:checkly/_shared/services/policy_manager.dart';
import 'package:checkly/_shared/router/auth_redirect.dart';

class MockBodAnalyticsManager extends Mock implements BodAnalyticsManager {}
class MockPolicyManager extends Mock implements PolicyManager {}

class _StubAuthManager extends ChangeNotifier implements AuthManager {
  final Set<String> _caps;
  _StubAuthManager({required Set<String> capabilities}) : _caps = capabilities;

  @override
  ValueListenable<AuthState> get authState => ValueNotifier(AuthState.authenticated);
  @override
  UserSession? get currentUser => const UserSession(
    userId: '1',
    fullName: 'Executive User',
    email: 'executive@checkly.com',
    role: 'admin',
    token: 'exec-token',
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
  late MockBodAnalyticsManager mockManager;

  setUp(() {
    mockManager = MockBodAnalyticsManager();
    final di = GetIt.instance;
    di.pushNewScope();
    di.registerFactory<BodAnalyticsManager>(() => mockManager);

    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
    when(() => mockManager.loadReport()).thenAnswer((_) async {});
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: BodAnalyticsPage(),
    );
  }

  final successReportComplete = BodReportResponse(
    chainKpis: {'totalAudits': 450, 'avgScore': 84.5},
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: {},
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z', // Needs localization in UI
    snapshotStatus: 'Complete',
    allowedActions: ['refresh'],
  );

  final successReportPartial = BodReportResponse(
    chainKpis: {'totalAudits': 450, 'avgScore': 84.5},
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: {},
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z',
    snapshotStatus: 'PartiallyFailed',
    allowedActions: ['refresh'],
  );

  group('BodAnalyticsPage Routing & Guard Tests', () {
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

    test('TC-BOD-ROUTING-01: Gated route blocks unauthorized and allows authorized', () {
      // 1. Block unauthorized role missing 'analytics:bod' capability
      arrangeCapabilities({'submissions:create'});
      final blockResult = authRedirect(MockBuildContext(), MockGoRouterState('/analytics/bod'));
      expect(blockResult, equals('/home'));

      // 2. Allow authorized role containing 'analytics:bod' capability
      // Note: Make sure AppCapabilities.analyticsBod is dynamically registered/checked
      arrangeCapabilities({'analytics:bod'});
      final allowResult = authRedirect(MockBuildContext(), MockGoRouterState('/analytics/bod'));
      expect(allowResult, isNull);
    });
  });

  group('BodAnalyticsPage Widget Tests', () {
    testWidgets('TC-BOD-UI-01: Displays localized ComputedAt timestamp and charts in success state', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.isOffline).thenReturn(false);
      when(() => mockManager.isEmpty).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.report).thenReturn(successReportComplete);

      await tester.pumpWidget(buildTestWidget());

      // Localized timestamp verify (UTC 02:15 gets localized depending on local system timezone)
      // Check if it displays localized date components or 'May 24, 2026' or dynamic timezone
      expect(find.textContaining('Data as of'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);

      // Verify no warning banner is present
      expect(find.textContaining('database timeouts'), findsNothing);
    });

    testWidgets('TC-BOD-UI-02: PartiallyFailed status renders a yellow warning banner', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.isOffline).thenReturn(false);
      when(() => mockManager.isEmpty).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.report).thenReturn(successReportPartial);

      await tester.pumpWidget(buildTestWidget());

      // Prominent yellow warning banner should render matching the text contract
      expect(
        find.textContaining('Some board metrics could not be fully calculated due to temporary database timeouts.'),
        findsOneWidget,
      );
    });

    testWidgets('TC-BOD-OFFLINE-01: API connection error displays standard ChecklyEmptyState offline retry view', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.isOffline).thenReturn(true);
      when(() => mockManager.isEmpty).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.report).thenReturn(null);

      await tester.pumpWidget(buildTestWidget());

      // Verify standard connection required error state is displayed
      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('Connection Required'), findsOneWidget);
      expect(find.textContaining('BOD Analytics requires an active internet connection'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Try Again'), findsOneWidget);

      // Tapping "Try Again" triggers refreshReport
      when(() => mockManager.refreshReport()).thenAnswer((_) async {});
      await tester.tap(find.widgetWithText(OutlinedButton, 'Try Again'));
      await tester.pump();

      verify(() => mockManager.refreshReport()).called(1);
    });

    testWidgets('TC-BOD-EMPTY-01: HTTP 404 returns boardroom dashboard empty state with recompute button', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.isOffline).thenReturn(false);
      when(() => mockManager.isEmpty).thenReturn(true);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.report).thenReturn(null);

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ChecklyEmptyState), findsOneWidget);
      expect(find.text('Boardroom Dashboard Empty'), findsOneWidget);
      expect(find.textContaining('No pre-computed report is available yet.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Trigger Recomputation'), findsOneWidget);

      // Tapping "Trigger Recomputation" triggers refreshReport in manager
      when(() => mockManager.refreshReport()).thenAnswer((_) async {});
      await tester.tap(find.widgetWithText(FilledButton, 'Trigger Recomputation'));
      await tester.pump();

      verify(() => mockManager.refreshReport()).called(1);
    });

    testWidgets('TC-BOD-UI-03: Verify all 6 chart panels are instances of StrokeCard', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.isOffline).thenReturn(false);
      when(() => mockManager.isEmpty).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.report).thenReturn(successReportComplete);

      await tester.pumpWidget(buildTestWidget());

      // We expect 6 Executive Dashboard cards wrapped in StrokeCard
      expect(find.byType(StrokeCard), findsNWidgets(6));
    });
  });
}
