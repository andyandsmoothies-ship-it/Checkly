// Test Contract: Pillar D — SyncEngine Backoff Tests
// AC4, AC5, AC6
// Author: Sentinel (SDET) / Executed: Builder (Forge)
//
// Strategy: inject real in-memory OutboxDao so AC4/AC5/AC6 verify actual DB state.
// This follows the Sentinel's DI Seam requirement (Option A: OutboxDao injected directly).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart' hide PendingSubmission;
import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/services/sync_engine.dart';
import 'package:checkly/_shared/services/sync_interfaces.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/sync_state.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

class AlwaysOnlineConnectivity implements ConnectivityService {
  @override bool get isOnline => true;
  @override Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class AlwaysAuthCheck implements AuthCheck {
  @override bool get isLoggedIn => true;
}

class FailingApi implements SyncApi {
  @override Future<void> pushSubmission(PendingSubmission s) async {
    throw Exception('Simulated network error');
  }
  @override Future<DeltaPullResult> pullDeltas(DateTime? since) async {
    return DeltaPullResult(serverTimestamp: DateTime.now().toUtc());
  }
}

class FakeOutbox implements Outbox {
  final List<PendingSubmission> _entries = [];

  @override List<PendingSubmission> get pending => List.unmodifiable(_entries);
  @override Future<void> add(PendingSubmission e) async => _entries.add(e);
  @override Future<void> remove(String key) async =>
      _entries.removeWhere((e) => e.idempotencyKey == key);

  void seed(String key) {
    _entries.add(PendingSubmission(
      idempotencyKey: key,
      createdAt: DateTime.now().toUtc(),
      payload: '{}',
    ));
  }
}

// No-op stubs for the evidence drain injection points.
class _FakeActionPlanApi implements ActionPlanApi {
  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async => ActionPlanDto(
    id: id,
    status: 'open',
    criteriaLabel: '',
    groupTitle: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// Not used by backoff tests. Satisfies the ActionPlanApi interface.
  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async => [];
}

class _FakeActionPlanOutboxDao implements ActionPlanOutboxDao {
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
  Future<int> pendingCount() async => 0;
}

// ─── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late OutboxDao dao;
  late FakeOutbox outbox;
  late SyncEngine engine;

  Future<String> seedEligibleSub({int retryCount = 0}) async {
    const id = 'sub-1';
    await dao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        templateId: 't1',
        storeId: 's1',
        clientScore: 100.0,
        idempotencyKey: id,
        retryCount: Value(retryCount),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    outbox.seed(id);
    return id;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OutboxDao(db);
    outbox = FakeOutbox();
    engine = SyncEngine(
      connectivity: AlwaysOnlineConnectivity(),
      api: FailingApi(),
      outbox: outbox,
      auth: AlwaysAuthCheck(),
      outboxDao: dao,
      actionPlanApi: _FakeActionPlanApi(),
      actionPlanOutboxDao: _FakeActionPlanOutboxDao(),
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  // ─── AC4: 1st failure → retryCount=1, nextRetryAt ≈ +2s ──────────────
  test('AC4: SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s', () async {
    await seedEligibleSub(retryCount: 0);
    final now = DateTime.now().toUtc();

    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    final row = rows.first;

    expect(row.retryCount, 1);
    expect(row.syncStatus, 'pending');
    expect(row.nextRetryAt, isNotNull);
    expect(
      row.nextRetryAt!.isAfter(now.add(const Duration(seconds: 1))),
      isTrue,
      reason: 'nextRetryAt must be at least 1s in the future',
    );
    expect(
      row.nextRetryAt!.isBefore(now.add(const Duration(seconds: 3))),
      isTrue,
      reason: 'nextRetryAt must be within 3s tolerance window',
    );
  });

  // ─── AC5: 3rd failure (retryCount==3) → nextRetryAt ≈ +60s ──────────
  test('AC5: SyncEngine_ThirdFailure_SetsNextRetryAt60s', () async {
    await seedEligibleSub(retryCount: 3);
    final now = DateTime.now().toUtc();

    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    final row = rows.first;

    expect(row.retryCount, 4);
    expect(row.syncStatus, 'pending');
    expect(
      row.nextRetryAt!.isAfter(now.add(const Duration(seconds: 59))),
      isTrue,
    );
    expect(
      row.nextRetryAt!.isBefore(now.add(const Duration(seconds: 61))),
      isTrue,
    );
  });

  // ─── AC6: 4th failure (retryCount==4) → status=exhausted ─────────────
  test('AC6: SyncEngine_FourthFailure_SetsStatusExhausted', () async {
    await seedEligibleSub(retryCount: 4);

    await engine.requestSync();

    final rows = await db.select(db.pendingSubmissions).get();
    final row = rows.first;

    expect(row.syncStatus, 'exhausted');
    expect(engine.state, SyncState.error);
  });
}
