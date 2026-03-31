/// Test Plan (Sentinel — Detroit Style)
/// ======================================
/// Target: AdminDashboardPage widget
///
/// Contract source: test_contracts_admin_ui_fixes.md §2
///
/// Contracts:
/// 1. API failure → SnackBar with error text is visible.
/// 2. API success → No SnackBar; counts update correctly.
/// 3. Layout → ConstrainedBox with maxWidth 600 exists in tree.
/// 4. Terminology → text 'OPEN PLANS' present; 'PENDING' must be absent.
///
/// Strategy: Use mocktail Mock classes for all GetIt-resolved services.
/// DashboardManager is concrete — mocked via mocktail.
/// Detroit style: Assert OBSERVABLE STATE only (widget tree, visible text).

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/pages/admin_dashboard_page.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/features/dashboard/manager/dashboard_manager.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/features/templates/services/template_api_service.dart';
import 'package:checkly/features/stores/model/store_dto.dart';
import 'package:checkly/features/templates/models/template_dto.dart';

// ── Mock declarations ─────────────────────────────────────────────────────────
// mocktail generates the correct override matching ANY method signature.
class _MockDashboardManager extends Mock implements DashboardManager {}
class _MockAdminApiService extends Mock implements AdminApiService {}
class _MockStoreApiService extends Mock implements StoreApiService {}
class _MockTemplateApiService extends Mock implements TemplateApiService {}

// ── Helpers ───────────────────────────────────────────────────────────────────

_MockDashboardManager _setupManager() {
  final m = _MockDashboardManager();
  when(() => m.isLoading).thenReturn(false);
  when(() => m.dashboardState).thenReturn(DashboardLoading());
  when(() => m.loadStats()).thenAnswer((_) async {});
  when(() => m.addListener(any())).thenReturn(null);
  when(() => m.removeListener(any())).thenReturn(null);
  when(() => m.hasListeners).thenReturn(false);
  return m;
}

void _registerDi({bool apiShouldThrow = false}) {
  final di = GetIt.instance;
  di.registerSingleton<DashboardManager>(_setupManager());

  final adminSvc = _MockAdminApiService();
  if (apiShouldThrow) {
    when(
      () => adminSvc.getUsersRaw(
        pageSize: any(named: 'pageSize'),
        page: any(named: 'page'),
      ),
    ).thenThrow(Exception('Network error'));
  } else {
    when(
      () => adminSvc.getUsersRaw(
        pageSize: any(named: 'pageSize'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => {'total': 5, 'items': []});
  }
  di.registerSingleton<AdminApiService>(adminSvc);

  final storeSvc = _MockStoreApiService();
  when(
    () => storeSvc.getStores(
      search: any(named: 'search'),
      areaId: any(named: 'areaId'),
      assignableAs: any(named: 'assignableAs'),
      exceptUser: any(named: 'exceptUser'),
      includeInactive: any(named: 'includeInactive'),
    ),
  ).thenAnswer((_) async => <StoreDto>[]);
  di.registerSingleton<StoreApiService>(storeSvc);

  final templateSvc = _MockTemplateApiService();
  when(() => templateSvc.getTemplates()).thenAnswer((_) async => <TemplateDto>[]);
  di.registerSingleton<TemplateApiService>(templateSvc);
}

Future<void> pumpAdminDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: AdminDashboardPage()));
  await tester.pump(); // initState postFrameCallback
  await tester.pump(const Duration(seconds: 1)); // async _loadCounts
}

// ── Test Suite ────────────────────────────────────────────────────────────────

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('AdminDashboard — Load Counts', () {
    testWidgets(
      'AdminDashboard_LoadCounts_ShowsSnackBarOnApiFailure — SnackBar visible when API throws',
      (tester) async {
        // VALID RED: Production has `catch (_) {}` that silently swallows the
        // exception (admin_dashboard_page.dart line 54).
        // Fix needed: ScaffoldMessenger.of(context).showSnackBar(...)
        _registerDi(apiShouldThrow: true);
        await pumpAdminDashboard(tester);

        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason: 'A SnackBar must appear when _loadCounts() throws.',
        );
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.textContaining('error', findRichText: true),
          ),
          findsOneWidget,
          reason: 'SnackBar must contain error text.',
        );
      },
    );

    testWidgets(
      'AdminDashboard_LoadCounts_SilentOnSuccess — No SnackBar on successful API call',
      (tester) async {
        // REGRESSION GUARD: Success path must never show a SnackBar.
        _registerDi();
        await pumpAdminDashboard(tester);

        expect(
          find.byType(SnackBar),
          findsNothing,
          reason: 'No SnackBar should appear on successful API response.',
        );
      },
    );
  });

  group('AdminDashboard — Layout', () {
    testWidgets(
      'AdminDashboard_Layout_RespectsMaxWidth — ConstrainedBox(maxWidth:600) in tree',
      (tester) async {
        // VALID RED: Current ListView is unconstrained (line 73).
        // Fix needed: wrap body with ConstrainedBox(maxWidth: 600).
        _registerDi();
        await pumpAdminDashboard(tester);

        final boxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
        final hasMaxWidth600 = boxes.any(
          (b) => b.constraints.maxWidth == 600.0,
        );

        expect(
          hasMaxWidth600,
          isTrue,
          reason: 'A ConstrainedBox(maxWidth:600) must exist for wide-screen layouts.',
        );
      },
    );
  });

  group('AdminDashboard — Terminology', () {
    testWidgets(
      'AdminDashboard_StatLabel_ShowsOpenPlans — OPEN PLANS visible, PENDING absent',
      (tester) async {
        // VALID RED: Production renders label: 'PENDING' (line 120).
        // Fix needed: change label to 'OPEN PLANS'.
        _registerDi();
        await pumpAdminDashboard(tester);

        expect(
          find.text('OPEN PLANS'),
          findsOneWidget,
          reason: "Stat card label must read 'OPEN PLANS'.",
        );
        expect(
          find.text('PENDING'),
          findsNothing,
          reason: "Old 'PENDING' label must be replaced.",
        );
      },
    );
  });
}
