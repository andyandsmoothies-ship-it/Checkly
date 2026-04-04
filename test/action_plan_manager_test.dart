// ATDD: Slice 5 — Action Plan State Machine (RED phase)
//
// These tests define the behavioral contract for ActionPlanManager
// which enforces role-based state transitions client-side.
// They will FAIL until the following files are implemented:
//   - lib/features/action_plans/model/action_plan_dto.dart
//   - lib/features/action_plans/manager/action_plan_manager.dart
//   - lib/features/action_plans/services/action_plan_api_service.dart
//
// Spec source: specs_slice5_action_plans.md
// Author: Sentinel (SDET)
// Status: 🔴 RED — production classes do not exist yet

import 'package:flutter_test/flutter_test.dart';

// --- IMPORTS (will fail until implemented) ---
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/app_database.dart';

// ============================================================
// Fake API and Auth for isolated testing
// ============================================================

/// Fake API that records calls without hitting the network.
class FakeActionPlanApi implements ActionPlanApi {
  ActionPlanDto? lastUpdated;

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async {
    // Simulate server accepting the update
    lastUpdated = ActionPlanDto(
      id: id,
      status: fields['status'] ?? 'open',
      criteriaLabel: 'Test Criteria',
      groupTitle: 'Test Section',
      correctionPlan: fields['correctionPlan'] as String?,
      evidenceNote: fields['evidenceNote'] as String?,
      evidencePhotoUrl: fields['evidencePhotoUrl'] as String?,
      closedAt: fields['status'] == 'closed' ? DateTime.now() : null,
      verifierName: fields['verifierName'] as String?,
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.now(),
    );
    return lastUpdated!;
  }
}

/// Minimal user role provider for testing role guards.
class FakeUserRole implements UserRoleProvider {
  String currentRole;
  FakeUserRole(this.currentRole);

  @override
  String get role => currentRole;
}

/// Always-online connectivity stub — preserves original test behaviour.
/// The online path calls the API, so existing assertions on api.lastUpdated hold.
class FakeConnectivityService implements ConnectivityService {
  bool online;
  FakeConnectivityService({this.online = true});

  @override
  bool get isOnline => online;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

/// No-op outbox DAO for unit tests — records enqueueing without a DB.
class FakeActionPlanOutboxDao implements ActionPlanOutboxDao {
  final List<PendingActionPlanUpdatesCompanion> enqueued = [];

  @override
  Future<void> enqueue(PendingActionPlanUpdatesCompanion entry) async {
    enqueued.add(entry);
  }

  @override
  Future<List<PendingActionPlanUpdate>> getEligiblePending() async => [];

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> markExhausted(String id, String error) async {}

  @override
  Future<int> pendingCount() async => 0;
}

// Helper to create an ActionPlanDto with a given status and deadline.
ActionPlanDto _makePlan({required String status, DateTime? deadline}) =>
    ActionPlanDto(
      id: 'ap-001',
      status: status,
      criteriaLabel: 'Criteria A',
      groupTitle: 'Section 1',
      deadline: deadline,
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.utc(2026, 3, 1),
    );

void main() {
  late FakeActionPlanApi api;
  late FakeUserRole userRole;
  late FakeConnectivityService connectivity;
  late FakeActionPlanOutboxDao outboxDao;
  late ActionPlanManager manager;

  setUp(() {
    api = FakeActionPlanApi();
    userRole = FakeUserRole('store_manager');
    connectivity = FakeConnectivityService(online: true); // online path by default
    outboxDao = FakeActionPlanOutboxDao();
    manager = ActionPlanManager(
      api: api,
      userRole: userRole,
      connectivity: connectivity,
      outboxDao: outboxDao,
    );
  });

  // ================================================================
  // Scenario 1: SM submits evidence → pending_verify
  // Source: CORE_WORKFLOWS.md §3 Lines 88-89
  // ================================================================
  test('S1: SM submits evidence → status = pending_verify', () async {
    final plan = _makePlan(status: 'open');
    userRole.currentRole = 'store_manager';

    final result = await manager.submitEvidence(
      plan,
      correctionPlan: 'Fix the issue',
      evidenceNote: 'Photo attached',
    );

    expect(result.status, 'pending_verify');
    expect(api.lastUpdated?.status, 'pending_verify');
  });

  // ================================================================
  // Scenario 2: Auditor closes pending_verify plan → closed
  // Source: CORE_WORKFLOWS.md §3 Lines 89-90
  // ================================================================
  test('S2: Auditor closes plan → status = closed', () async {
    final plan = _makePlan(status: 'pending_verify');
    userRole.currentRole = 'auditor';

    final result = await manager.closePlan(plan, verifierName: 'Nguyễn Văn A');

    expect(result.status, 'closed');
    expect(result.closedAt, isNotNull);
    expect(result.verifierName, 'Nguyễn Văn A');
  });

  // ================================================================
  // Scenario 3: Auditor rejects evidence → back to open
  // Source: CORE_WORKFLOWS.md §3 Line 77
  // ================================================================
  test('S3: Auditor rejects evidence → status = open', () async {
    final plan = _makePlan(status: 'pending_verify');
    userRole.currentRole = 'auditor';

    final result = await manager.rejectEvidence(plan);

    expect(result.status, 'open');
  });

  // ================================================================
  // Scenario 4: SM cannot close a plan (role guard)
  // Source: CORE_WORKFLOWS.md §3 Lines 89-90, analysis Line 271
  // ================================================================
  test('S4: SM cannot close plan — throws RoleGuardException', () async {
    final plan = _makePlan(status: 'pending_verify');
    userRole.currentRole = 'store_manager';

    expect(
      () => manager.closePlan(plan, verifierName: 'SM Trying'),
      throwsA(isA<RoleGuardException>()),
    );
    // API should NOT have been called
    expect(api.lastUpdated, isNull);
  });

  // ================================================================
  // Scenario 5: Auditor cannot submit evidence (role guard)
  // Source: CORE_WORKFLOWS.md §3 Line 88
  // ================================================================
  test(
    'S5: Auditor cannot submit evidence — throws RoleGuardException',
    () async {
      final plan = _makePlan(status: 'open');
      userRole.currentRole = 'auditor';

      expect(
        () => manager.submitEvidence(
          plan,
          correctionPlan: 'Fix',
          evidenceNote: 'Note',
        ),
        throwsA(isA<RoleGuardException>()),
      );
      expect(api.lastUpdated, isNull);
    },
  );

  // ================================================================
  // Scenario 6: Cannot transition from closed (terminal state)
  // Source: CORE_WORKFLOWS.md §3 Line 90: "Closed = Immutable"
  // ================================================================
  test('S6: Closed is terminal — any transition throws', () async {
    final plan = _makePlan(status: 'closed');
    userRole.currentRole = 'auditor';

    expect(
      () => manager.rejectEvidence(plan),
      throwsA(isA<InvalidTransitionException>()),
    );
    expect(api.lastUpdated, isNull);
  });

  // ================================================================
  // Scenario 7: Overdue detection
  // Source: CORE_WORKFLOWS.md §3 Lines 122-125
  // ================================================================
  test('S7: Open plan past deadline is overdue', () {
    final plan = _makePlan(
      status: 'open',
      deadline: DateTime.utc(2026, 3, 1), // In the past
    );

    expect(
      ActionPlanManager.isOverdue(plan, now: DateTime.utc(2026, 3, 11)),
      isTrue,
    );
  });

  test('S7b: Closed plan past deadline is NOT overdue', () {
    final plan = _makePlan(
      status: 'closed',
      deadline: DateTime.utc(2026, 3, 1),
    );

    expect(
      ActionPlanManager.isOverdue(plan, now: DateTime.utc(2026, 3, 11)),
      isFalse,
    );
  });

  // ================================================================
  // Scenario 8: Valid transitions per status
  // Source: CORE_WORKFLOWS.md §3 Lines 72-82
  // ================================================================
  test('S8: Allowed transitions per status', () {
    expect(ActionPlanManager.allowedTransitions('open'), ['pending_verify']);
    expect(
      ActionPlanManager.allowedTransitions('pending_verify'),
      unorderedEquals(['closed', 'open']),
    );
    expect(ActionPlanManager.allowedTransitions('closed'), isEmpty);
  });
}
