/// Test Plan (Sentinel — Detroit Style)
/// ======================================
/// Target: AuditApprovalPage widget
///
/// W-2 Coverage Gap Fix: Admin pages had zero behavioral tests.
///
/// Contracts:
/// 1. Loading state → shows CircularProgressIndicator.
/// 2. Error state → shows error text + Retry button.
/// 3. Happy path → completed submissions appear in the Pending tab as ReviewCard.
/// 4. Search filter → filters list by store name query.
///
/// Strategy:
/// - AdminAuditManager is concrete — instantiated with mock service deps
///   injected directly through the constructor (no GetIt needed for the manager).
/// - SubmissionApiService is registered in GetIt because the page resolves it
///   directly via `_di<SubmissionApiService>()` for approve/reject mutations.
/// - Detroit style: Assert OBSERVABLE STATE only (widget tree, visible text).

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/admin/manager/admin_audit_manager.dart';
import 'package:checkly/features/admin/pages/audit_approval_page.dart';
import 'package:checkly/features/admin/services/admin_api_service.dart';
import 'package:checkly/features/audit/model/submission_dto.dart';
import 'package:checkly/features/audit/services/submission_api_service.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/features/stores/services/store_api_service.dart';
import 'package:checkly/features/templates/services/template_api_service.dart';

// ── Mock declarations ──────────────────────────────────────────────────────────

class _MockSubmissionApiService extends Mock implements SubmissionApiService {}

class _MockAdminApiService extends Mock implements AdminApiService {}

class _MockStoreApiService extends Mock implements StoreApiService {}

class _MockTemplateApiService extends Mock implements TemplateApiService {}

class _MockAuthManager extends Mock implements AuthManager {}

// ── Fixtures ───────────────────────────────────────────────────────────────────

SubmissionDto _makeSubmission({
  String id = 'sub-1',
  String storeName = 'Store Alpha',
  String? reviewStatus,
  String status = 'completed',
}) =>
    SubmissionDto(
      id: id,
      storeName: storeName,
      templateTitle: 'Template A',
      auditorName: 'Alice',
      status: status,
      createdAt: DateTime(2026, 1, 1),
      reviewStatus: reviewStatus,
      scoringMode: 'penalty',
      totalScore: 85.0,
      rawEarnedPoints: 85,
      rawMaxPoints: 100,
    );

// ── Test helpers ───────────────────────────────────────────────────────────────

/// Creates a real AdminAuditManager with all mock service deps injected.
AdminAuditManager _makeManager(_MockSubmissionApiService submissionSvc) {
  return AdminAuditManager(
    adminApi: _MockAdminApiService(),
    storeApi: _MockStoreApiService(),
    templateApi: _MockTemplateApiService(),
    submissionApi: submissionSvc,
    auth: _MockAuthManager(),
  );
}

/// Pumps AuditApprovalPage. The manager is registered in GetIt so the page's
/// `_di<AdminAuditManager>()` call resolves to our test instance.
Future<void> _pump(
  WidgetTester tester, {
  required _MockSubmissionApiService submissionSvc,
}) async {
  final manager = _makeManager(submissionSvc);
  GetIt.instance.registerSingleton<AdminAuditManager>(manager);
  GetIt.instance.registerSingleton<SubmissionApiService>(submissionSvc);

  await tester.pumpWidget(const MaterialApp(home: AuditApprovalPage()));
  await tester.pump(); // initState
  await tester.pump(const Duration(seconds: 1)); // async loadApprovals
}

// ── Test Suite ─────────────────────────────────────────────────────────────────

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('AuditApprovalPage — Loading State', () {
    testWidgets(
      'AuditApproval_Loading_ShowsProgressIndicator — '
      'CircularProgressIndicator visible while manager is loading',
      (tester) async {
        final svc = _MockSubmissionApiService();
        // Use a Completer that never completes to freeze the loading state.
        // This avoids the "pending Timer" assertion from Future.delayed.
        final completer = Completer<List<SubmissionDto>>();
        when(
          () => svc.getSubmissions(pageSize: any(named: 'pageSize')),
        ).thenAnswer((_) => completer.future);

        final manager = _makeManager(svc);
        GetIt.instance.registerSingleton<AdminAuditManager>(manager);
        GetIt.instance.registerSingleton<SubmissionApiService>(svc);

        await tester.pumpWidget(const MaterialApp(home: AuditApprovalPage()));
        await tester.pump(); // initState — kicks off loadApprovals, still pending

        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
          reason: 'A loading indicator must be visible while loadApprovals runs.',
        );

        // Resolve the completer so the widget disposes cleanly.
        completer.complete([]);
        await tester.pumpAndSettle();
      },
    );
  });

  group('AuditApprovalPage — Error State', () {
    testWidgets(
      'AuditApproval_Error_ShowsRetryButton — '
      'Error text and Retry button visible when API throws',
      (tester) async {
        final svc = _MockSubmissionApiService();
        when(
          () => svc.getSubmissions(pageSize: any(named: 'pageSize')),
        ).thenThrow(Exception('Network error'));

        await _pump(tester, submissionSvc: svc);

        expect(
          find.text('Error loading audits'),
          findsOneWidget,
          reason: 'Error heading must be shown on API failure.',
        );
        expect(
          find.text('Retry'),
          findsOneWidget,
          reason: 'A Retry button must be visible so the admin can recover.',
        );
      },
    );
  });

  group('AuditApprovalPage — Happy Path', () {
    testWidgets(
      'AuditApproval_HappyPath_PendingTabShowsCard — '
      'Pending submission appears as a ReviewCard in the default tab',
      (tester) async {
        final svc = _MockSubmissionApiService();
        when(
          () => svc.getSubmissions(pageSize: any(named: 'pageSize')),
        ).thenAnswer((_) async => [_makeSubmission()]);

        await _pump(tester, submissionSvc: svc);

        expect(
          find.text('Store Alpha'),
          findsOneWidget,
          reason: 'The pending submission store name must appear in the Pending tab.',
        );
      },
    );

    testWidgets(
      'AuditApproval_HappyPath_SearchFiltersResults — '
      'Typing a search query filters the visible list',
      (tester) async {
        final svc = _MockSubmissionApiService();
        when(
          () => svc.getSubmissions(pageSize: any(named: 'pageSize')),
        ).thenAnswer(
          (_) async => [
            _makeSubmission(id: 'sub-1', storeName: 'Store Alpha'),
            _makeSubmission(id: 'sub-2', storeName: 'Store Beta'),
          ],
        );

        await _pump(tester, submissionSvc: svc);

        // Both items start visible.
        expect(find.text('Store Alpha'), findsOneWidget);
        expect(find.text('Store Beta'), findsOneWidget);

        // Type a query that only matches "Beta".
        await tester.enterText(find.byType(TextField), 'beta');
        await tester.pump();

        expect(
          find.text('Store Alpha'),
          findsNothing,
          reason: '"Store Alpha" must be hidden when query is "beta".',
        );
        expect(
          find.text('Store Beta'),
          findsOneWidget,
          reason: '"Store Beta" must remain visible when query is "beta".',
        );
      },
    );
  });
}
