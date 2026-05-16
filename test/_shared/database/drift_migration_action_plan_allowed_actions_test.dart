// Phase B TDD — Drift Schema Migration: cached_allowed_actions column
//
// Tests: B2, B3, B4
// - B2: CachedActionPlans stores allowedActions as serialized JSON.
// - B3: Schema migration v28 preserves existing cached rows.
// - B4: Offline loadActionPlans rehydrates allowedActions from cache.
//
// Source: implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md
// Author: Sentinel (QA)
// Status: 🔴 RED — CachedActionPlans has no cachedAllowedActions column,
//         schemaVersion is 27, and the manager read-path does not map the field.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';
import 'package:checkly/_shared/services/connectivity_service.dart';
import 'package:checkly/_shared/services/user_role_provider.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test fakes (minimal — no network, no real outbox)
// ─────────────────────────────────────────────────────────────────────────────

class _FakeApi implements ActionPlanApi {
  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async => [];

  @override
  Future<ActionPlanDto?> fetchActionPlan(String id) async => null;

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async => throw UnimplementedError();

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async =>
      throw UnimplementedError();

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) async => throw UnimplementedError();
}

class _FakeOutbox implements ActionPlanOutboxDao {
  @override
  Future<void> enqueue(PendingActionPlanUpdatesCompanion entry) async {}

  @override
  Future<List<PendingActionPlanUpdate>> getEligiblePending() async => [];

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
  Future<String?> getSubmissionIdForPlan(String planId) async => null;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> updateRetry(
    String id,
    int newRetryCount,
    DateTime nextRetry,
    String error,
  ) async {}
}

class _FakeUserRole implements UserRoleProvider {
  @override
  String get role => 'store_manager';
}

class _FakeConnectivity implements ConnectivityService {
  bool online;
  _FakeConnectivity({this.online = false});

  @override
  bool get isOnline => online;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Seeds a single CachedActionPlans row with a cachedAllowedActions JSON value.
/// Will FAIL until the Builder adds the `cachedAllowedActions` column (B2/B3/B4 RED).
Future<void> _seedCachedPlanWithActions(
  AppDatabase db, {
  required String id,
  required List<String> actions,
}) async {
  await db
      .into(db.cachedActionPlans)
      .insert(
        CachedActionPlansCompanion.insert(
          id: id,
          criteriaLabel: 'Food Safety',
          groupTitle: 'Hygiene',
          status: const Value('open'),
          cachedAllowedActions: Value(jsonEncode(actions)), // <-- NEW COLUMN
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        ),
      );
}

/// Seeds a row without the cachedAllowedActions column (simulates a v27 row).
Future<void> _seedLegacyCachedPlan(AppDatabase db, {required String id}) async {
  await db
      .into(db.cachedActionPlans)
      .insert(
        CachedActionPlansCompanion.insert(
          id: id,
          criteriaLabel: 'Legacy Criteria',
          groupTitle: 'Legacy Group',
          status: const Value('open'),
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Force schema creation (lazy init)
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  // ===========================================================================
  // B2 — CachedActionPlans stores allowedActions as serialized JSON
  // ===========================================================================
  group(
    'B2: CachedActionPlans.cachedAllowedActions column exists and round-trips',
    () {
      test(
        'B2a: Can write and read back a JSON-encoded allowedActions list',
        () async {
          // Act: insert a row with cachedAllowedActions
          await _seedCachedPlanWithActions(
            db,
            id: 'ap-b2-001',
            actions: ['view', 'submit_evidence'],
          );

          // Read back
          final rows = await db.select(db.cachedActionPlans).get();
          expect(rows, hasLength(1));

          final row = rows.first;

          // Assert column is present and parseable
          expect(
            row.cachedAllowedActions, // <-- NEW COLUMN on the generated type
            isNotNull,
            reason:
                'cachedAllowedActions column must exist in CachedActionPlans. '
                'Builder must add it to tables.dart and bump schemaVersion to 28.',
          );

          final decoded = jsonDecode(row.cachedAllowedActions!) as List;
          expect(decoded, containsAll(['view', 'submit_evidence']));
        },
      );

      test(
        'B2b: Stores null when allowedActions is not available (safe fallback)',
        () async {
          // Insert a row without actions (no allowedActions from server)
          await _seedLegacyCachedPlan(db, id: 'ap-b2-null');

          final rows = await db.select(db.cachedActionPlans).get();
          final row = rows.first;

          // null is valid — the column is nullable
          expect(
            row.cachedAllowedActions,
            isNull,
            reason:
                'cachedAllowedActions must be nullable for backward compat.',
          );
        },
      );

      test(
        'B2c: Overwrites stored actions on insertOrReplace (cache upsert)',
        () async {
          await _seedCachedPlanWithActions(
            db,
            id: 'ap-b2-upsert',
            actions: ['view', 'submit_evidence'],
          );

          // Simulate a second sync: update to pending_verify actions
          await db
              .into(db.cachedActionPlans)
              .insert(
                CachedActionPlansCompanion.insert(
                  id: 'ap-b2-upsert',
                  criteriaLabel: 'Food Safety',
                  groupTitle: 'Hygiene',
                  status: const Value('pending_verify'),
                  cachedAllowedActions: const Value(
                    '["view","verify_close","reject_evidence"]',
                  ),
                  createdAt: DateTime.utc(2026, 5, 1),
                  updatedAt: DateTime.utc(2026, 5, 2),
                ),
                mode: InsertMode.insertOrReplace,
              );

          final rows = await db.select(db.cachedActionPlans).get();
          expect(
            rows,
            hasLength(1),
            reason: 'upsert must not create a duplicate row',
          );

          final decoded = jsonDecode(rows.first.cachedAllowedActions!) as List;
          expect(decoded, contains('verify_close'));
          expect(decoded, isNot(contains('submit_evidence')));
        },
      );
    },
  );

  // ===========================================================================
  // B3 — Schema migration v28 preserves existing cached rows
  // ===========================================================================
  group('B3: Schema v28 migration preserves legacy v27 rows', () {
    test(
      'B3a: Rows written before v28 migration remain readable after upgrade',
      () async {
        // We use a fresh in-memory DB (starts at latest schema via onCreate).
        // Simulate an existing row that was written without cachedAllowedActions.
        await _seedLegacyCachedPlan(db, id: 'ap-legacy-001');

        // Now insert a v28-style row with allowedActions
        await _seedCachedPlanWithActions(
          db,
          id: 'ap-v28-001',
          actions: ['view', 'submit_evidence'],
        );

        final rows = await db.select(db.cachedActionPlans).get();
        expect(
          rows,
          hasLength(2),
          reason:
              'Both the legacy row (null actions) and the v28 row must survive '
              'after migration. No rows should be deleted.',
        );

        final legacy = rows.firstWhere((r) => r.id == 'ap-legacy-001');
        final v28 = rows.firstWhere((r) => r.id == 'ap-v28-001');

        expect(
          legacy.cachedAllowedActions,
          isNull,
          reason: 'Legacy rows must default to null for cachedAllowedActions.',
        );
        expect(
          v28.cachedAllowedActions,
          isNotNull,
          reason: 'v28 rows must carry the JSON-encoded action list.',
        );
      },
    );

    test('B3b: Schema version is at least 28 after migration', () async {
      // The schemaVersion on AppDatabase must be bumped by the Builder.
      // This test reads the version from the generated _$AppDatabase class.
      // It fails because schemaVersion is currently 27.
      expect(
        db.schemaVersion,
        greaterThanOrEqualTo(28),
        reason:
            'Builder must set schemaVersion => 28 and add the migration '
            'step in app_database.dart.',
      );
    });
  });

  // ===========================================================================
  // B4 — Offline loadActionPlans rehydrates allowedActions from cache
  // ===========================================================================
  group('B4: Manager.loadActionPlans rehydrates allowedActions offline', () {
    test(
      'B4a: ActionPlanDto loaded from cache has allowedActions set',
      () async {
        // Arrange: seed the cache with one plan that has allowedActions
        await _seedCachedPlanWithActions(
          db,
          id: 'ap-b4-001',
          actions: ['view', 'submit_evidence'],
        );

        final manager = ActionPlanManager(
          api: _FakeApi(),
          userRole: _FakeUserRole(),
          connectivity: _FakeConnectivity(online: false), // offline path
          outboxDao: _FakeOutbox(),
          db: db,
        );

        // Act: load from cache
        await manager.loadActionPlans();

        // Assert
        expect(
          manager.actionPlans.value,
          hasLength(1),
          reason: 'Manager should load the seeded plan from cache.',
        );

        final dto = manager.actionPlans.value.first;

        expect(
          dto.allowedActions,
          isNotNull,
          reason:
              'Manager must map cachedAllowedActions back to allowedActions '
              'when building DTOs from cache rows.',
        );
        expect(dto.allowedActions, containsAll(['view', 'submit_evidence']));
      },
    );

    test(
      'B4b: Cache row with null cachedAllowedActions produces DTO with null allowedActions',
      () async {
        // Arrange: seed a legacy row without actions
        await _seedLegacyCachedPlan(db, id: 'ap-b4-null');

        final manager = ActionPlanManager(
          api: _FakeApi(),
          userRole: _FakeUserRole(),
          connectivity: _FakeConnectivity(online: false),
          outboxDao: _FakeOutbox(),
          db: db,
        );

        await manager.loadActionPlans();

        final dto = manager.actionPlans.value.first;

        // null from cache → null in DTO (safe; ActionPlanActionGuard handles fail-closed)
        expect(
          dto.allowedActions,
          isNull,
          reason:
              'A cached row with null actions must produce a DTO with '
              'null allowedActions, not an empty list.',
        );
      },
    );

    test(
      'B4c: Multiple plans rehydrate their individual allowedActions independently',
      () async {
        // Arrange: two plans with different action sets
        await _seedCachedPlanWithActions(
          db,
          id: 'ap-b4-open',
          actions: ['view', 'submit_evidence'],
        );
        await _seedCachedPlanWithActions(
          db,
          id: 'ap-b4-pv',
          actions: ['view', 'verify_close', 'reject_evidence'],
        );

        final manager = ActionPlanManager(
          api: _FakeApi(),
          userRole: _FakeUserRole(),
          connectivity: _FakeConnectivity(online: false),
          outboxDao: _FakeOutbox(),
          db: db,
        );

        await manager.loadActionPlans();

        expect(manager.actionPlans.value, hasLength(2));

        final openDto = manager.actionPlans.value.firstWhere(
          (d) => d.id == 'ap-b4-open',
        );
        final pvDto = manager.actionPlans.value.firstWhere(
          (d) => d.id == 'ap-b4-pv',
        );

        expect(openDto.allowedActions, contains('submit_evidence'));
        expect(openDto.allowedActions, isNot(contains('verify_close')));

        expect(pvDto.allowedActions, contains('verify_close'));
        expect(pvDto.allowedActions, isNot(contains('submit_evidence')));
      },
    );
  });
}
