import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:checkly/_shared/database/app_database.dart';

// ============================================================
// Test Plan: 90-Day SQLite Garbage Collector (Pillar A)
//  
// AC1 — Happy Path: completed/voided records > 90 days are pruned (submissions + action plans)
// AC2 — Preservation: records < 90 days are NOT pruned
// AC3 — NULL Safety: records with NULL completedAt/voidedAt are NOT pruned
// AC4 — Status Safety: draft/scheduled records are NEVER pruned regardless of age
// ============================================================

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Helper: insert a submission and linked action plan.
  Future<void> _seedSubmissionWithPlan(
    String id, {
    required String status,
    DateTime? completedAt,
    DateTime? voidedAt,
  }) async {
    await db.into(db.cachedSubmissions).insert(
      CachedSubmissionsCompanion.insert(
        id: id,
        status: status,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        completedAt: Value(completedAt),
        voidedAt: Value(voidedAt),
      ),
    );
    await db.into(db.cachedActionPlans).insert(
      CachedActionPlansCompanion.insert(
        id: 'ap-$id',
        criteriaLabel: 'Criteria',
        groupTitle: 'Group',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        submissionId: Value(id),
      ),
    );
  }

  // ── AC1: Happy Path (GC prunes stale completed + voided) ──

  test(
    'AC1a — GC_PruneStaleCompletedAudits: completed record > 90 days is deleted on db open',
    () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 91));
      await _seedSubmissionWithPlan('sub-stale-completed',
          status: 'completed', completedAt: staleDate);

      // Act: Trigger pruning logic directly. 
      // Do NOT re-assign `db` or call `db.close()` here, as it breaks isolation for subsequent tests
      // in the same suite. The NativeDatabase.memory() is torn down correctly in `tearDown`.
      await db.pruneStaleAuditsForTesting(); // Builder must expose this @visibleForTesting

      final subs = await db.select(db.cachedSubmissions).get();
      final plans = await db.select(db.cachedActionPlans).get();

      expect(subs.where((s) => s.id == 'sub-stale-completed'), isEmpty,
          reason: 'Stale completed submission must be pruned');
      expect(plans.where((p) => p.submissionId == 'sub-stale-completed'), isEmpty,
          reason: 'Orphaned action plan must be cascade-pruned');
    },
  );

  test(
    'AC1b — GC_PruneStaleVoidedAudits: voided record > 90 days is deleted on db open',
    () async {
      final staleDate = DateTime.now().subtract(const Duration(days: 91));
      await _seedSubmissionWithPlan('sub-stale-voided',
          status: 'voided', voidedAt: staleDate);

      await db.pruneStaleAuditsForTesting();

      final subs = await db.select(db.cachedSubmissions).get();
      final plans = await db.select(db.cachedActionPlans).get();

      expect(subs.where((s) => s.id == 'sub-stale-voided'), isEmpty,
          reason: 'Stale voided submission must be pruned');
      expect(plans.where((p) => p.submissionId == 'sub-stale-voided'), isEmpty,
          reason: 'Orphaned action plan for voided submission must be cascade-pruned');
    },
  );

  // ── AC2: Preservation (recent audits NOT pruned) ──

  test(
    'AC2 — GC_PreservesRecentAudits: completed record < 90 days is NOT deleted',
    () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      await _seedSubmissionWithPlan('sub-recent',
          status: 'completed', completedAt: recentDate);

      await db.pruneStaleAuditsForTesting();

      final subs = await db.select(db.cachedSubmissions).get();
      expect(subs.any((s) => s.id == 'sub-recent'), isTrue,
          reason: 'Recent completed submission must NOT be pruned');
    },
  );

  // ── AC3: NULL Safety ──

  test(
    'AC3 — GC_NullCompletedAt_NoDelete: completed record with NULL completedAt is NOT pruned',
    () async {
      await db.into(db.cachedSubmissions).insert(
        CachedSubmissionsCompanion.insert(
          id: 'sub-null-completed',
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
          completedAt: const Value(null), // explicitly null
        ),
      );

      await db.pruneStaleAuditsForTesting();

      final subs = await db.select(db.cachedSubmissions).get();
      expect(subs.any((s) => s.id == 'sub-null-completed'), isTrue,
          reason: 'NULL completedAt must be SQLite-safe — row must survive pruning');
    },
  );

  // ── AC4: Status Safety (draft/scheduled never pruned) ──

  test(
    'AC4 — GC_NeverPrunesDraftOrScheduled: draft and scheduled records are immune regardless of age',
    () async {
      // Seed very old draft and scheduled records
      final ancientDate = DateTime.now().subtract(const Duration(days: 365));
      await db.into(db.cachedSubmissions).insert(
        CachedSubmissionsCompanion.insert(
          id: 'sub-old-draft',
          status: 'draft',
          createdAt: ancientDate,
        ),
      );
      await db.into(db.cachedSubmissions).insert(
        CachedSubmissionsCompanion.insert(
          id: 'sub-old-scheduled',
          status: 'scheduled',
          createdAt: ancientDate,
        ),
      );

      await db.pruneStaleAuditsForTesting();

      final subs = await db.select(db.cachedSubmissions).get();
      expect(subs.any((s) => s.id == 'sub-old-draft'), isTrue,
          reason: 'Draft records are NEVER subject to GC pruning');
      expect(subs.any((s) => s.id == 'sub-old-scheduled'), isTrue,
          reason: 'Scheduled records are NEVER subject to GC pruning');
    },
  );
}
