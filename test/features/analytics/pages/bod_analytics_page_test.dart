import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/features/analytics/pages/bod_analytics_page.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/features/analytics/widgets/bod_store_detail_sheet.dart';
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
  ValueListenable<AuthState> get authState =>
      ValueNotifier(AuthState.authenticated);
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
    when(() => mockManager.isLiveMode).thenReturn(false);
    when(() => mockManager.activeProvince).thenReturn(null);
    when(() => mockManager.activeDistrict).thenReturn(null);
  });

  tearDown(() {
    GetIt.instance.popScope();
  });

  Widget buildTestWidget() {
    return const MaterialApp(home: BodAnalyticsPage());
  }

  final successReportComplete = BodReportResponse(
    chainKpis: BodChainKpis(totalAudits: 450, avgScore: 84.5, avgTtrDays: 0.0),
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: BodApAging(
      bucket0to30: 0,
      bucket31to60: 0,
      bucket61to90: 0,
      bucket90Plus: 0,
    ),
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z', // Needs localization in UI
    snapshotStatus: 'Complete',
    allowedActions: ['refresh'],
  );

  final successReportPartial = BodReportResponse(
    chainKpis: BodChainKpis(totalAudits: 450, avgScore: 84.5, avgTtrDays: 0.0),
    trend: [],
    topStores: [],
    bottomStores: [],
    categoryBreakdown: [],
    apAging: BodApAging(
      bucket0to30: 0,
      bucket31to60: 0,
      bucket61to90: 0,
      bucket90Plus: 0,
    ),
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z',
    snapshotStatus: 'PartiallyFailed',
    allowedActions: ['refresh'],
  );

  final successReportWithBenchAndTrend = BodReportResponse(
    chainKpis: BodChainKpis(totalAudits: 450, avgScore: 84.5, avgTtrDays: 0.0),
    trend: [
      {'period': '2026-04', 'avgScore': 81.0},
      {'period': '2026-05', 'avgScore': 84.5},
    ],
    topStores: [
      BodStorePerformanceEntry(
        storeId: 'store-1',
        storeName: 'Siam Square',
        avgScore: 96.5,
        auditCount: 15,
        lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ],
    bottomStores: [
      BodStorePerformanceEntry(
        storeId: 'store-2',
        storeName: 'Airport Express',
        avgScore: 58.4,
        auditCount: 10,
        lastSyncedAt: null,
      ),
    ],
    categoryBreakdown: [],
    apAging: BodApAging(
      bucket0to30: 0,
      bucket31to60: 0,
      bucket61to90: 0,
      bucket90Plus: 0,
    ),
    auditorProductivity: [],
    computedAt: '2026-05-24T02:15:00Z',
    snapshotStatus: 'Complete',
    allowedActions: ['refresh'],
    goldenStore: BodGoldenStore(
      storeId: 'store-1',
      storeName: 'Siam Square',
      avgScore: 96.5,
    ),
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

    test(
      'TC-BOD-ROUTING-01: Gated route blocks unauthorized and allows authorized',
      () {
        // 1. Block unauthorized role missing 'analytics:bod' capability
        arrangeCapabilities({'submissions:create'});
        final blockResult = authRedirect(
          MockBuildContext(),
          MockGoRouterState('/analytics/bod'),
        );
        expect(blockResult, equals('/home'));

        // 2. Allow authorized role containing 'analytics:bod' capability
        // Note: Make sure AppCapabilities.analyticsBod is dynamically registered/checked
        arrangeCapabilities({'analytics:bod'});
        final allowResult = authRedirect(
          MockBuildContext(),
          MockGoRouterState('/analytics/bod'),
        );
        expect(allowResult, isNull);
      },
    );
  });

  group('BodAnalyticsPage Widget Tests', () {
    testWidgets(
      'TC-BOD-UI-01: Displays localized ComputedAt timestamp and charts in success state',
      (tester) async {
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
      },
    );

    testWidgets(
      'TC-BOD-UI-02: PartiallyFailed status renders a yellow warning banner',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(successReportPartial);

        await tester.pumpWidget(buildTestWidget());

        // Prominent yellow warning banner should render matching the text contract
        expect(
          find.textContaining(
            'Some board metrics could not be fully calculated due to temporary database timeouts.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-BOD-OFFLINE-01: API connection error displays standard ChecklyEmptyState offline retry view',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(true);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        // Verify standard connection required error state is displayed
        expect(find.byType(ChecklyEmptyState), findsOneWidget);
        expect(find.text('Connection Required'), findsOneWidget);
        expect(
          find.textContaining(
            'BOD Analytics requires an active internet connection',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Try Again'),
          findsOneWidget,
        );

        // Tapping "Try Again" triggers refreshReport
        when(() => mockManager.refreshReport()).thenAnswer((_) async {});
        await tester.tap(find.widgetWithText(OutlinedButton, 'Try Again'));
        await tester.pump();

        verify(() => mockManager.refreshReport()).called(1);
      },
    );

    testWidgets(
      'TC-BOD-EMPTY-01: HTTP 404 returns boardroom dashboard empty state with recompute button',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(true);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(null);

        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(ChecklyEmptyState), findsOneWidget);
        expect(find.text('Boardroom Dashboard Empty'), findsOneWidget);
        expect(
          find.textContaining('No pre-computed report is available yet.'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Trigger Recomputation'),
          findsOneWidget,
        );

        // Tapping "Trigger Recomputation" triggers refreshReport in manager
        when(() => mockManager.refreshReport()).thenAnswer((_) async {});
        await tester.tap(
          find.widgetWithText(FilledButton, 'Trigger Recomputation'),
        );
        await tester.pump();

        verify(() => mockManager.refreshReport()).called(1);
      },
    );

    testWidgets(
      'TC-BOD-UI-03: Verify all 6 chart panels are instances of StrokeCard',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(() => mockManager.report).thenReturn(successReportComplete);

        await tester.pumpWidget(buildTestWidget());

        // We expect 6 Executive Dashboard cards wrapped in StrokeCard
        expect(find.byType(StrokeCard), findsNWidgets(6));
      },
    );

    testWidgets(
      'TC-BOD-SLICE5-01: Displays MoM Delta and Golden Flagship Benchmark text',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(
          () => mockManager.report,
        ).thenReturn(successReportWithBenchAndTrend);

        await tester.pumpWidget(buildTestWidget());

        // Verify average score is 84.5%
        expect(find.text('84.5%'), findsWidgets);

        // Verify comparison text showing "88% of flagship (Siam Square 96.5%)"
        // Note: 84.5 / 96.5 * 100 = 87.56...%, which rounds to "88%"
        expect(
          find.textContaining('88% of flagship (Siam Square 96.5%)'),
          findsOneWidget,
        );

        // Verify MoM delta chip shows upward arrow and 3.5% (84.5 - 81.0 = 3.5)
        expect(find.text('↑ 3.5%'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-BOD-SLICE5-02: Leaderboard row shows sync dot status and opens store detail sheet on tap',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);
        when(
          () => mockManager.report,
        ).thenReturn(successReportWithBenchAndTrend);

        // Stub the store detail load
        when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
        when(() => mockManager.isStoreDetailLoading).thenReturn(false);
        when(() => mockManager.storeDetail).thenReturn(StoreBodSummary(
          storeName: 'Siam Square',
          recentAudits: [
            RecentAuditEntry(date: '2026-05-24T14:30:00Z', score: 96.5, auditorName: 'Alice'),
          ],
          categoryBreakdown: [],
        ));

        await tester.pumpWidget(buildTestWidget());

        // Scroll the Siam Square row into view before tapping
        final rowFinder = find.text('Siam Square');
        await tester.ensureVisible(rowFinder);
        await tester.pumpAndSettle();

        // Find the top store row "Siam Square" and tap it
        await tester.tap(rowFinder);
        await tester.pumpAndSettle();

        // Verify store detail modal sheet is opened
        expect(find.byType(BodStoreDetailSheet), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BodStoreDetailSheet),
            matching: find.text('Siam Square'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Live data as of'), findsOneWidget);

        // Close the modal
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(BodStoreDetailSheet), findsNothing);
      },
    );

    testWidgets(
      'TC-BOD-SLICE6-01: AP Aging Funnel shows TTR pill and taps bucket to show bottom sheet',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);

        final reportWithAp = BodReportResponse(
          chainKpis: const BodChainKpis(
            totalAudits: 450,
            avgScore: 84.5,
            avgTtrDays: 5.5,
          ),
          trend: [],
          topStores: [],
          bottomStores: [],
          categoryBreakdown: [],
          apAging: const BodApAging(
            bucket0to30: 10,
            bucket31to60: 5,
            bucket61to90: 2,
            bucket90Plus: 1,
          ),
          auditorProductivity: [],
          computedAt: '2026-05-24T02:15:00Z',
          snapshotStatus: 'Complete',
          allowedActions: ['refresh'],
        );
        when(() => mockManager.report).thenReturn(reportWithAp);

        await tester.pumpWidget(buildTestWidget());

        // 1. Verify AP aging title and average resolution time pill exist
        expect(find.text('Action Plan Aging'), findsOneWidget);
        expect(find.text('Avg TTR: 5.5 Days'), findsOneWidget);

        // 2. Verify bucket count displays
        expect(find.text('10'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        // 3. Stub details sheet loading state
        when(() => mockManager.isApDetailLoading).thenReturn(false);
        when(() => mockManager.apDetails).thenReturn([
          ApDetailEntry(
            id: '11111111-2222-3333-4444-555555555555',
            criteriaLabel: 'Temperature Logs',
            storeName: 'Central Market',
            managerName: 'Andy Manager',
            ageInDays: 12,
          ),
        ]);
        when(() => mockManager.loadApDetails(any())).thenAnswer((_) async {});

        // 4. Tap the first bucket (0-30 Days)
        final firstBucket = find.text('0-30 Days');
        await tester.ensureVisible(firstBucket);
        await tester.pumpAndSettle();
        await tester.tap(firstBucket);
        await tester.pumpAndSettle();

        // 5. Verify the sheet is displayed and displays universal list card with items
        expect(find.text('0-30 Days Overdue Action Plans'), findsOneWidget);
        expect(find.text('Store: Central Market'), findsOneWidget);
        expect(find.text('Manager: Andy Manager'), findsOneWidget);
        expect(find.text('12 Days Overdue'), findsOneWidget);

        // Close sheet
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'TC-BOD-SLICE7-01: Score Trend displays raw values, computes SMA, and shows Trajectory Pill',
      (tester) async {
        when(() => mockManager.isLoading).thenReturn(false);
        when(() => mockManager.isOffline).thenReturn(false);
        when(() => mockManager.isEmpty).thenReturn(false);
        when(() => mockManager.error).thenReturn(null);

        final trendData = [
          {'month': 'Jan 2026', 'avgScore': 80.0, 'count': 10},
          {'month': 'Feb 2026', 'avgScore': 84.0, 'count': 10},
          {'month': 'Mar 2026', 'avgScore': 88.0, 'count': 10},
          {'month': 'Apr 2026', 'avgScore': 90.0, 'count': 10},
        ];

        final reportWithTrend = BodReportResponse(
          chainKpis: const BodChainKpis(
            totalAudits: 450,
            avgScore: 84.5,
            avgTtrDays: 0.0,
          ),
          trend: trendData,
          topStores: [],
          bottomStores: [],
          categoryBreakdown: [],
          apAging: const BodApAging(
            bucket0to30: 0,
            bucket31to60: 0,
            bucket61to90: 0,
            bucket90Plus: 0,
          ),
          auditorProductivity: [],
          computedAt: '2026-05-24T02:15:00Z',
          snapshotStatus: 'Complete',
          allowedActions: ['refresh'],
        );
        when(() => mockManager.report).thenReturn(reportWithTrend);

        await tester.pumpWidget(buildTestWidget());

        // 1. Verify trend card title
        expect(find.text('Historical Score Trend'), findsOneWidget);

        // 2. Verify score values displayed
        expect(find.text('80.0%'), findsOneWidget);
        expect(find.text('84.0%'), findsOneWidget);
        expect(find.text('88.0%'), findsOneWidget);
        expect(find.text('90.0%'), findsOneWidget);

        // 3. Verify Smoothed calculations:
        // Jan & Feb don't have Smoothed (since window=3)
        // Mar Smoothed = (80 + 84 + 88)/3 = 84.0%
        // Apr Smoothed = (84 + 88 + 90)/3 = 87.33% => 87.3%
        expect(find.text('Smoothed: 84.0%'), findsOneWidget);
        expect(find.text('Smoothed: 87.3%'), findsOneWidget);

        // 4. Verify Trend chip shows Going up (since Apr Smoothed 87.3% > Mar Smoothed 84.0%)
        expect(find.textContaining('Trend: Going up'), findsOneWidget);
      },
    );
  });
}
