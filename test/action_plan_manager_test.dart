// ATDD: Slice 5 — Action Plan State Machine + Pull Engine (RED phase)
//
// These tests define the behavioral contract for ActionPlanManager
// which enforces role-based state transitions client-side.
// They will FAIL until the following files are implemented:
//   - lib/features/action_plans/model/action_plan_dto.dart
//   - lib/features/action_plans/manager/action_plan_manager.dart
//   - lib/features/action_plans/services/action_plan_api_service.dart
//
// Spec source: specs_slice5_action_plans.md + test_contracts_action_plan_sync.md
// Author: Sentinel (SDET)
// Status: 🔴 RED — pull-engine production methods do not exist yet

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// --- IMPORTS (will fail until implemented) ---
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
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

  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async => [];

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'mock_photo_url';

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) async {
    return CommentDto(
      id: 'comment-123',
      userId: 'user-123',
      body: request.body,
      createdAt: DateTime.now(),
    );
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
  Future<void> markStaleConflict(String id) async {}

  @override
  Future<PendingActionPlanUpdate?> getStaleConflictForPlan(String planId) async => null;

  @override
  Future<String?> getSubmissionIdForPlan(String planId) async => null;

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
      currentUserName: 'Test User',
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
          currentUserName: 'Test User',
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

  // ================================================================
  // Pull Engine group — AP_PULL_01/02/03
  // ================================================================
  group('Pull Engine', pullEngineTests);
}

// ============================================================
// [NEW] Pull Engine Fakes — AP_PULL_01/02/03
// ============================================================

/// Fake API that also implements fetchActionPlans() — required by the pull engine.
/// AP_PULL_01/02/03 require this method to exist on ActionPlanApi.
/// RED: ActionPlanApi currently does NOT declare fetchActionPlans().
class FakeActionPlanApiWithFetch implements ActionPlanApi {
  final List<ActionPlanDto> _plans;
  bool fetchWasCalled = false;
  bool shouldThrow = false;

  FakeActionPlanApiWithFetch(this._plans);

  /// [AP_PULL_01 / AP_PULL_03] — counts invocations and optionally throws.
  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async {
    fetchWasCalled = true;
    if (shouldThrow) throw Exception('Network timeout');
    return _plans;
  }

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'mock_photo_url';

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async {
    return _plans.first;
  }

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) async {
    return CommentDto(
      id: 'comment-123',
      userId: 'user-123',
      body: request.body,
      createdAt: DateTime.now(),
    );
  }
}

/// Seeds `cachedActionPlans` with a single open plan row.
Future<void> _seedOneCachedPlan(AppDatabase db) async {
  await db.into(db.cachedActionPlans).insert(
    CachedActionPlansCompanion.insert(
      id: 'cached-ap-001',
      criteriaLabel: 'Criteria A',
      groupTitle: 'Section 1',
      status: const Value('open'),
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.utc(2026, 3, 1),
    ),
  );
}

/// Returns two dummy [ActionPlanDto] instances for pull engine tests.
List<ActionPlanDto> _twoRemotePlans() => [
  ActionPlanDto(
    id: 'remote-ap-001',
    status: 'open',
    criteriaLabel: 'Remote Criteria A',
    groupTitle: 'Remote Section 1',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
  ),
  ActionPlanDto(
    id: 'remote-ap-002',
    status: 'pending_verify',
    criteriaLabel: 'Remote Criteria B',
    groupTitle: 'Remote Section 2',
    createdAt: DateTime.utc(2026, 4, 2),
    updatedAt: DateTime.utc(2026, 4, 2),
  ),
];

// ============================================================
// [NEW] Pull Engine Tests — Action Plan Sync Contracts
// Contract source: test_contracts_action_plan_sync.md
// ============================================================
void pullEngineTests() {
  // Each test gets a fresh in-memory DB and a clean manager.
  // The manager receives the AppDatabase directly, bypassing the DI container.
  // RED: loadActionPlans() currently ignores the injected db parameter and calls
  // _di<DatabaseService>().db — so these will fail until Builder adds the `db`
  // constructor parameter and uses it in loadActionPlans().

  late AppDatabase db;
  late FakeActionPlanApiWithFetch api;
  late FakeConnectivityService connectivity;
  late FakeActionPlanOutboxDao outboxDao;
  late FakeUserRole userRole;
  late ActionPlanManager manager;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // After creation, trigger schema onCreate so all tables exist.
    await db.customStatement('SELECT 1'); // forces lazy init
    api = FakeActionPlanApiWithFetch(_twoRemotePlans());
    connectivity = FakeConnectivityService(online: true);
    outboxDao = FakeActionPlanOutboxDao();
    userRole = FakeUserRole('auditor');

    // RED: ActionPlanManager does not yet accept `db` as a constructor param.
    manager = ActionPlanManager(
      api: api,
      userRole: userRole,
      connectivity: connectivity,
      outboxDao: outboxDao,
      db: db, // <-- This constructor param does not exist yet → compile error
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ================================================================
  // AP_PULL_01: Online — fetches from API, caches to DB, reads cache
  // Contract: test_contracts_action_plan_sync.md §Contract 01
  // ================================================================
  test(
    'AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads',
    () async {
      // Arrange
      connectivity.online = true;
      // api returns _twoRemotePlans() by default

      // Act
      await manager.loadActionPlans();

      // Assert 1: network was called exactly once
      expect(api.fetchWasCalled, isTrue);

      // Assert 2: in-memory ValueNotifier has 2 items
      expect(manager.actionPlans.value, hasLength(2));

      // Assert 3: both items were written to the real in-memory SQLite cache
      final cached = await db.select(db.cachedActionPlans).get();
      expect(cached, hasLength(2));
    },
  );

  // ================================================================
  // AP_PULL_02: Offline — reads only from cache, never calls network
  // Contract: test_contracts_action_plan_sync.md §Contract 02
  // ================================================================
  test(
    'AP_PULL_02: Manager_LoadActionPlans_WhenOffline_ReadsFromCacheOnly',
    () async {
      // Arrange: pre-seed 1 item into cache and go offline
      await _seedOneCachedPlan(db);
      connectivity.online = false;

      // Act
      await manager.loadActionPlans();

      // Assert 1: network was NEVER called
      expect(api.fetchWasCalled, isFalse);

      // Assert 2: reads the 1 cached item
      expect(manager.actionPlans.value, hasLength(1));
    },
  );

  // ================================================================
  // AP_PULL_03: Network error — gracefully falls back to cache
  // Contract: test_contracts_action_plan_sync.md §Contract 03
  // ================================================================
  test(
    'AP_PULL_03: Manager_LoadActionPlans_WhenNetworkFails_GracefullyReadsCache',
    () async {
      // Arrange: online but api throws, 1 row pre-seeded in cache
      await _seedOneCachedPlan(db);
      connectivity.online = true;
      api.shouldThrow = true;

      // Act — must not throw
      await expectLater(manager.loadActionPlans(), completes);

      // Assert 1: API was called (it threw)
      expect(api.fetchWasCalled, isTrue);

      // Assert 2: exception was swallowed — no crash

      // Assert 3: falls back to the single cached item
      expect(manager.actionPlans.value, hasLength(1));
    },
  );
}

