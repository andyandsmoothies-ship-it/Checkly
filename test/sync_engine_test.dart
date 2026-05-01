// ATDD: Slice 2 — Sync Engine + Connectivity Monitor (RED phase)
//
// These tests define the behavioral contract for the SyncEngine state machine.
// They will FAIL until the following files are implemented:
//   - lib/_shared/services/sync_engine.dart
//   - lib/_shared/services/connectivity_service.dart
//   - lib/_shared/services/sync_state.dart
//
// Spec source: specs_slice2_sync_engine.md
// Author: Sentinel (SDET)
// Status: 🔴 RED — production classes do not exist yet

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// --- IMPORTS (will fail until implemented) ---
import 'package:checkly/_shared/database/app_database.dart'
    hide PendingSubmission;
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/sync_meta_dao.dart';
import 'package:checkly/_shared/database/dao/program_outbox_dao.dart';
import 'package:checkly/_shared/services/sync_engine.dart';
import 'package:checkly/_shared/services/pending_submission.dart';
import 'package:checkly/_shared/services/delta_pull_result.dart';
import 'package:checkly/_shared/services/pending_submission_risk.dart';
import 'package:checkly/_shared/services/sync_api.dart';
import 'package:checkly/_shared/services/outbox.dart';
import 'package:checkly/_shared/services/auth_check.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/sync_state.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';

// ============================================================
// Fake dependencies for testing SyncEngine in isolation
// ============================================================

/// Fake connectivity service that allows manual control of online/offline.
class FakeConnectivityService implements ConnectivityService {
  bool _isOnline = true;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  final _controller = StreamController<bool>.broadcast(sync: true);

  void setOnline() {
    _isOnline = true;
    _controller.add(true);
  }

  void setOffline() {
    _isOnline = false;
    _controller.add(false);
  }

  void dispose() => _controller.close();
}

/// Tracks API calls made by the sync engine for verification.
class FakeSyncApi implements SyncApi {
  final List<String> pushLog = [];
  final List<String> pullLog = [];

  /// If set, push for this submission ID will throw a generic network error.
  String? failOnPushId;

  /// If set, push for this submission ID will throw a 403 Forbidden error.
  String? throw403OnId;

  /// Simulated last sync timestamp returned by delta endpoints.
  DateTime serverTimestamp = DateTime.utc(2026, 3, 11, 12, 0, 0);

  int pushCallCount = 0;

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    pushLog.add(submission.idempotencyKey);
    pushCallCount++;
    if (submission.idempotencyKey == throw403OnId) {
      throw Exception(
        'DioException 403 Forbidden: Permission denied for ${submission.idempotencyKey}',
      );
    }
    if (submission.idempotencyKey == failOnPushId) {
      throw Exception('Network error on ${submission.idempotencyKey}');
    }
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async {
    pullLog.add(since?.toIso8601String() ?? 'null');
    return DeltaPullResult(serverTimestamp: serverTimestamp);
  }

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async => [];

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {}

  @override
  Future<List<dynamic>> pullProgramAssignments() async => [];

  @override
  Future<void> pushProgramEvidence(
    String assignmentId,
    List<Map<String, dynamic>> evidenceItems,
  ) async {}

  @override
  Future<void> pushProgramPhoto(String photoLocalKey, String filePath) async {}
}

/// Fake outbox (in-memory) for testing FIFO ordering and removal.
class FakeOutbox implements Outbox {
  final List<PendingSubmission> _entries = [];

  @override
  List<PendingSubmission> get pending => List.unmodifiable(_entries);

  @override
  Future<void> add(PendingSubmission entry) async => _entries.add(entry);

  @override
  Future<void> remove(String idempotencyKey) async =>
      _entries.removeWhere((e) => e.idempotencyKey == idempotencyKey);

  void addAll(List<PendingSubmission> entries) => _entries.addAll(entries);
}

/// Fake auth state for testing auth-aware sync.
class FakeAuthCheck implements AuthCheck {
  bool isAuthenticated = true;

  @override
  bool get isLoggedIn => isAuthenticated;
}

// Helper to create a PendingSubmission with a given key and timestamp.
PendingSubmission _makePending(String key, DateTime createdAt) =>
    PendingSubmission(idempotencyKey: key, createdAt: createdAt, payload: '{}');

// No-op stubs for the new SyncEngine injection points.
class _FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      'http://example.com/photo.jpg';
  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async => ActionPlanDto(
    id: id,
    status: fields['status'] ?? 'open',
    criteriaLabel: '',
    groupTitle: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Not used by sync engine tests. Satisfies the ActionPlanApi interface.
  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async => [];

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) => Future.error('not used');

  @override
  Future<ActionPlanDto?> fetchActionPlan(String id) async => null;
}

class _FakeActionPlanOutboxDao implements ActionPlanOutboxDao {
  @override
  Future<String?> getSubmissionIdForPlan(String planId) async => 'sub_123';
  _FakeActionPlanOutboxDao();
  @override
  Future<List<PendingActionPlanUpdate>> getEligiblePending() async => [];
  @override
  Future<void> enqueue(PendingActionPlanUpdatesCompanion entry) async {}
  @override
  Future<void> remove(String id) async {}
  @override
  Future<void> markExhausted(String id, String error) async {}
  @override
  Future<void> markStaleConflict(String id) async {}
  @override
  Future<PendingActionPlanUpdate?> getStaleConflictForPlan(
    String planId,
  ) async => null;
  @override
  Future<int> pendingCount() async => 0;
}

void main() {
  late FakeConnectivityService connectivity;
  late FakeSyncApi api;
  late FakeOutbox outbox;
  late FakeAuthCheck auth;
  late SyncEngine engine;

  late OutboxDao outboxDao;
  late AppDatabase testDb;

  setUp(() {
    connectivity = FakeConnectivityService();
    api = FakeSyncApi();
    outbox = FakeOutbox();
    auth = FakeAuthCheck();
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    outboxDao = OutboxDao(testDb);
    engine = SyncEngine(
      connectivity: connectivity,
      api: api,
      outbox: outbox,
      auth: auth,
      outboxDao: outboxDao,
      actionPlanApi: _FakeActionPlanApi(),
      actionPlanOutboxDao: _FakeActionPlanOutboxDao(),
      globalRiskDao: GlobalRiskDao(testDb),
      submissionRiskOutboxDao: SubmissionRiskOutboxDao(testDb),
      syncMetaDao: SyncMetaDao(testDb),
      programOutboxDao: ProgramOutboxDao(testDb),
    );
  });

  tearDown(() async {
    engine.dispose();
    connectivity.dispose();
    await testDb.close();
  });

  // ================================================================
  // Scenario 1: offline → online triggers sync
  // Source: analysis §Slice 2, Line 212
  // ================================================================
  test('S1: Connectivity online triggers sync cycle', () async {
    connectivity.setOffline();
    expect(engine.state, SyncState.offline);

    connectivity.setOnline();
    // Allow sync to process
    await Future.delayed(Duration(milliseconds: 100));

    // Sync should have run (pull was called)
    expect(api.pullLog, isNotEmpty);
    expect(engine.state, SyncState.idle);
  });

  // ================================================================
  // Scenario 2: No concurrent sync — second request is ignored
  // Source: analysis §2.3 Edge Case #7
  // ================================================================
  test('S2: Concurrent sync request is ignored', () async {
    // Start a sync
    final firstSync = engine.requestSync();

    // Request another while first is running
    final secondSync = engine.requestSync();

    await firstSync;
    await secondSync;

    // Pull should only be called once
    expect(api.pullLog.length, 1);
  });

  // ================================================================
  // Helper to sync test data into both FakeOutbox and OutboxDao
  // ================================================================
  Future<void> seedData(List<PendingSubmission> entries) async {
    outbox.addAll(entries);
    for (var e in entries) {
      await outboxDao.insertSubmission(
        PendingSubmissionsCompanion.insert(
          id: e.idempotencyKey,
          templateId: 't',
          storeId: 's',
          clientScore: 100.0,
          idempotencyKey: e.idempotencyKey,
          createdAt: e.createdAt,
        ),
      );
    }
  }

  // ================================================================
  // Scenario 3: Outbox drains in FIFO order
  // Source: CORE_WORKFLOWS.md §7 Line 237, analysis §2.3 Edge Case #1
  // ================================================================
  test('S3: Outbox pushed in FIFO order by createdAt', () async {
    await seedData([
      _makePending('C', DateTime.utc(2026, 3, 11, 3)),
      _makePending('A', DateTime.utc(2026, 3, 11, 1)),
      _makePending('B', DateTime.utc(2026, 3, 11, 2)),
    ]);

    await engine.requestSync();

    // Must push in chronological order A → B → C
    expect(api.pushLog, ['A', 'B', 'C']);
    // Outbox should be empty after successful sync
    final remainingRows = await outboxDao.getEligiblePending();
    expect(remainingRows, isEmpty);
  });

  // ================================================================
  // Scenario 4: Partial push failure — resume from last success
  // Source: analysis §2.3 Edge Case #2
  // ================================================================
  test('S4: Partial failure stops at failed item, keeps remaining', () async {
    await seedData([
      _makePending('A', DateTime.utc(2026, 3, 11, 1)),
      _makePending('B', DateTime.utc(2026, 3, 11, 2)),
      _makePending('C', DateTime.utc(2026, 3, 11, 3)),
    ]);
    api.failOnPushId = 'B';

    await engine.requestSync();

    // A should have been pushed and removed
    expect(api.pushLog, ['A', 'B']); // B was attempted
    final allPending = await testDb.select(testDb.pendingSubmissions).get();
    expect(allPending.map((e) => e.idempotencyKey).toList(), ['B', 'C']);
    expect(engine.state, SyncState.error);
  });

  // ================================================================
  // Scenario 5: Delta pull updates lastSyncTimestamp
  // Source: analysis §Slice 2 Line 221
  // ================================================================
  test('S5: Delta pull uses and updates lastSyncTimestamp', () async {
    engine.lastSyncTimestamp = DateTime.utc(2026, 3, 10);
    api.serverTimestamp = DateTime.utc(2026, 3, 11, 8, 0, 0);

    await engine.requestSync();

    // Pull should have been called with the old timestamp
    expect(api.pullLog, ['2026-03-10T00:00:00.000Z']);
    // After sync, timestamp should be updated to server's response
    expect(engine.lastSyncTimestamp, DateTime.utc(2026, 3, 11, 8, 0, 0));
  });

  // ================================================================
  // Scenario 6: Sync skipped when not authenticated
  // Source: CORE_WORKFLOWS.md §7 Line 239
  // ================================================================
  test('S6: Sync skipped when user is not authenticated', () async {
    auth.isAuthenticated = false;

    await engine.requestSync();

    // No API calls should have been made
    expect(api.pullLog, isEmpty);
    expect(api.pushLog, isEmpty);
    expect(engine.state, SyncState.idle);
  });

  // ================================================================
  // Scenario 7: Empty outbox — pull-only sync
  // Source: analysis §Slice 2 Lines 213-214
  // ================================================================
  test('S7: Empty outbox only pulls, no push', () async {
    // Outbox is empty by default

    await engine.requestSync();

    expect(api.pullLog, isNotEmpty);
    expect(api.pushLog, isEmpty);
    expect(engine.state, SyncState.idle);
  });

  // ================================================================
  // Scenario 8: Connectivity lost during sync → offline
  // Source: analysis §Slice 2 Line 215
  // ================================================================
  test('S8: Connectivity loss during sync transitions to offline', () async {
    // Add entries so sync takes time
    await seedData([_makePending('A', DateTime.utc(2026, 3, 11, 1))]);

    // Make push slow and drop connectivity mid-way
    api.failOnPushId = 'A'; // Simulates failure (network drop)
    connectivity.setOffline();

    await engine.requestSync();

    // Engine should reflect offline state
    expect(engine.state, SyncState.offline);
  });

  // ================================================================
  // Scenario 9: 403 Forbidden exhausts record immediately, no retry
  // Source: PBAC Slice 5 -- Fatal 403 Resilience
  // PM Safety Mandate: demoted users trigger battery drain loop without this guard.
  // ================================================================
  test(
    'S9: 403 Forbidden immediately exhausts record without retrying',
    () async {
      await seedData([_makePending('A', DateTime.utc(2026, 3, 11, 1))]);
      api.throw403OnId = 'A';

      await engine.requestSync();

      // The record must be exhausted
      final rows = await testDb.select(testDb.pendingSubmissions).get();
      expect(rows.length, 1);
      expect(rows.first.syncStatus, 'exhausted');
      expect(rows.first.syncError, contains('FATAL 403'));

      // retryCount must still be 0 -- no backoff was attempted before exhaustion
      expect(rows.first.retryCount, 0);

      // Push was called exactly ONCE (no retry)
      expect(api.pushCallCount, 1);
    },
  );

  // ================================================================
  // Scenario 10: 403 on first record does NOT abort remaining batch
  // Source: PBAC Slice 5 -- Fatal 403 Resilience
  // Verifies `continue` (not `return`) is used in the catch block.
  // ================================================================
  test('S10: 403 on one record continues syncing remaining records', () async {
    await seedData([
      _makePending('A', DateTime.utc(2026, 3, 11, 1)), // will get 403
      _makePending('B', DateTime.utc(2026, 3, 11, 2)), // should succeed
    ]);
    api.throw403OnId = 'A';

    await engine.requestSync();

    // A should be exhausted
    final rowA = (await testDb.select(testDb.pendingSubmissions).get())
        .where((r) => r.id == 'A')
        .single;
    expect(rowA.syncStatus, 'exhausted');
    expect(rowA.syncError, contains('FATAL 403'));

    // B should have been removed (synced successfully)
    final rowB = (await testDb.select(testDb.pendingSubmissions).get())
        .where((r) => r.id == 'B')
        .toList();
    expect(
      rowB,
      isEmpty,
      reason: 'B should be removed from outbox after success',
    );

    // Both push calls were made (A attempted once, B succeeded)
    expect(api.pushLog, ['A', 'B']);
  });
}
