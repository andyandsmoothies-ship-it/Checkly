import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/features/analytics/manager/analytics_drift_loader.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  /// Seeds a minimal store and submission into the in-memory database.
  Future<void> seedSubmission({
    required String id,
    required DateTime createdAt,
    String storeId = 's1',
    String storeName = 'Store A',
    String addressProvince = 'North',
    String status = 'completed',
    String? reviewStatus,
    double? totalScore,
    String? auditorName,
    String templateId = 't1',
    String templateType = 'food_safety',
    String? categoryTag,
  }) async {
    final now = DateTime.now();

    // Ensure store exists (ignore conflict if already inserted)
    await db
        .into(db.cachedStores)
        .insertOnConflictUpdate(
          CachedStoresCompanion.insert(
            id: storeId,
            name: storeName,
            addressProvince: Value(addressProvince),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Ensure template exists
    await db
        .into(db.cachedTemplates)
        .insertOnConflictUpdate(
          CachedTemplatesCompanion.insert(
            id: templateId,
            title: templateType,
            type: templateType,
            version: const Value(1),
            isActive: const Value(true),
            categoryTag: Value(categoryTag),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.cachedSubmissions)
        .insert(
          CachedSubmissionsCompanion.insert(
            id: id,
            templateId: Value(templateId),
            storeId: Value(storeId),
            storeName: Value(storeName),
            auditorName: Value(auditorName),
            status: status,
            reviewStatus: Value(reviewStatus),
            totalScore: Value(totalScore),
            createdAt: createdAt,
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('SELECT 1');
  });

  tearDown(() async {
    await db.close();
  });

  // ── Helper that calls loadFromDrift with all defaults ──────────────────────

  Future<dynamic> load({
    String? selectedProvince,
    String? selectedStore,
    String? selectedType,
    String? selectedAuditor,
    String? selectedStatus,
    String? selectedReviewStatus,
    String? selectedCategoryTag,
    String dateRange = 'all',
    DateTimeRange? customDateRange,
  }) => loadFromDrift(
    db: db,
    selectedProvince: selectedProvince,
    selectedStore: selectedStore,
    selectedType: selectedType,
    selectedAuditor: selectedAuditor,
    selectedStatus: selectedStatus,
    selectedReviewStatus: selectedReviewStatus,
    selectedCategoryTag: selectedCategoryTag,
    dateRange: dateRange,
    customDateRange: customDateRange,
  );

  // ── Date-range filters ─────────────────────────────────────────────────────

  group('Date-range filtering', () {
    test(
      'DL-01: dateRange=30 excludes submissions older than 30 days',
      () async {
        final now = DateTime.now();
        await seedSubmission(
          id: 'recent',
          createdAt: now.subtract(const Duration(days: 5)),
        );
        await seedSubmission(
          id: 'old',
          createdAt: now.subtract(const Duration(days: 45)),
        );

        final data = await load(dateRange: '30');

        expect(
          data.totalAudits,
          1,
          reason: 'Only the 5-day-old submission should match',
        );
      },
    );

    test(
      'DL-02: dateRange=90 excludes submissions older than 90 days',
      () async {
        final now = DateTime.now();
        await seedSubmission(
          id: 'r1',
          createdAt: now.subtract(const Duration(days: 60)),
        );
        await seedSubmission(
          id: 'r2',
          createdAt: now.subtract(const Duration(days: 100)),
        );

        final data = await load(dateRange: '90');

        expect(
          data.totalAudits,
          1,
          reason: 'Only the 60-day-old submission should match',
        );
      },
    );

    test(
      'DL-03: dateRange=all returns every non-rejected submission',
      () async {
        final now = DateTime.now();
        await seedSubmission(
          id: 'a',
          createdAt: now.subtract(const Duration(days: 365)),
        );
        await seedSubmission(
          id: 'b',
          createdAt: now.subtract(const Duration(days: 1)),
        );

        final data = await load(dateRange: 'all');

        expect(data.totalAudits, 2);
      },
    );

    test(
      'DL-04: custom date range returns only submissions within range',
      () async {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 20));
        final end = now.subtract(const Duration(days: 10));

        await seedSubmission(
          id: 'inside',
          createdAt: now.subtract(const Duration(days: 15)),
        );
        await seedSubmission(
          id: 'before',
          createdAt: now.subtract(const Duration(days: 25)),
        );
        await seedSubmission(
          id: 'after',
          createdAt: now.subtract(const Duration(days: 5)),
        );

        final data = await load(
          dateRange: 'custom',
          customDateRange: DateTimeRange(start: start, end: end),
        );

        expect(
          data.totalAudits,
          1,
          reason: 'Only the submission inside the range should match',
        );
      },
    );
  });

  // ── Review-status exclusion ────────────────────────────────────────────────

  test('DL-05: rejected submissions are always excluded', () async {
    final now = DateTime.now();
    await seedSubmission(id: 'ok', createdAt: now, reviewStatus: 'approved');
    await seedSubmission(
      id: 'rejected',
      createdAt: now,
      reviewStatus: 'rejected',
    );

    final data = await load();

    expect(
      data.totalAudits,
      1,
      reason: 'Rejected submissions must be filtered out',
    );
  });

  // ── Multi-filter chaining ──────────────────────────────────────────────────

  group('Multi-filter chaining', () {
    test('DL-06: area + date range are AND-combined', () async {
      final now = DateTime.now();

      // North area, within 30d → should match
      await seedSubmission(
        id: 'n-recent',
        createdAt: now.subtract(const Duration(days: 5)),
        storeId: 's1',
        storeName: 'Store A',
        addressProvince: 'North',
      );
      // North area, older than 30d → excluded by date
      await seedSubmission(
        id: 'n-old',
        createdAt: now.subtract(const Duration(days: 60)),
        storeId: 's1',
        storeName: 'Store A',
        addressProvince: 'North',
      );
      // South area, within 30d → excluded by area filter
      await seedSubmission(
        id: 's-recent',
        createdAt: now.subtract(const Duration(days: 5)),
        storeId: 's2',
        storeName: 'Store B',
        addressProvince: 'South',
      );

      final data = await load(selectedProvince: 'North', dateRange: '30');

      expect(
        data.totalAudits,
        1,
        reason: 'Only North + recent submission should survive both filters',
      );
    });

    test('DL-07: store + auditor filters chain correctly', () async {
      final now = DateTime.now();

      await seedSubmission(
        id: 'match',
        createdAt: now,
        storeName: 'Store A',
        auditorName: 'Alice',
      );
      await seedSubmission(
        id: 'wrong-store',
        createdAt: now,
        storeId: 's2',
        storeName: 'Store B',
        auditorName: 'Alice',
      );
      await seedSubmission(
        id: 'wrong-auditor',
        createdAt: now,
        storeName: 'Store A',
        auditorName: 'Bob',
      );

      final data = await load(
        selectedStore: 'Store A',
        selectedAuditor: 'Alice',
      );

      expect(
        data.totalAudits,
        1,
        reason: 'Store A + Alice must both be satisfied',
      );
    });

    test('DL-08: status filter works in combination with date range', () async {
      final now = DateTime.now();

      // Completed, within 30d → match
      await seedSubmission(
        id: 'c-recent',
        createdAt: now.subtract(const Duration(days: 5)),
        status: 'completed',
      );
      // In-progress, within 30d → excluded by status
      await seedSubmission(
        id: 'ip-recent',
        createdAt: now.subtract(const Duration(days: 3)),
        status: 'in_progress',
      );
      // Completed, old → excluded by date
      await seedSubmission(
        id: 'c-old',
        createdAt: now.subtract(const Duration(days: 60)),
        status: 'completed',
      );

      final data = await load(selectedStatus: 'completed', dateRange: '30');

      expect(data.totalAudits, 1);
    });
  });

  group('CategoryTag offline filtering', () {
    test(
      'DL-09: populates categoryTagNames dynamically and filters by selected category tag',
      () async {
        final now = DateTime.now();

        await seedSubmission(
          id: 'sub1',
          createdAt: now,
          templateId: 't1',
          templateType: 'food_safety',
          categoryTag: 'Quality',
        );
        await seedSubmission(
          id: 'sub2',
          createdAt: now,
          templateId: 't2',
          templateType: 'health_safety',
          categoryTag: 'Safety',
        );
        await seedSubmission(
          id: 'sub3',
          createdAt: now,
          templateId: 't3',
          templateType: 'cleaning',
          categoryTag: 'Quality',
        );
        await seedSubmission(
          id: 'sub4',
          createdAt: now,
          templateId: 't4',
          templateType: 'survey',
          categoryTag: null,
        );

        // 1. Check without categoryTag filter
        final dataNoFilter = await load(dateRange: 'all');
        expect(dataNoFilter.categoryTagNames, ['Quality', 'Safety']);
        expect(dataNoFilter.totalAudits, 4);

        // 2. Filter by 'Quality'
        final dataQuality = await load(
          selectedCategoryTag: 'Quality',
          dateRange: 'all',
        );
        expect(dataQuality.categoryTagNames, ['Quality', 'Safety']);
        expect(dataQuality.totalAudits, 2);

        // 3. Filter by 'Safety'
        final dataSafety = await load(
          selectedCategoryTag: 'Safety',
          dateRange: 'all',
        );
        expect(dataSafety.categoryTagNames, ['Quality', 'Safety']);
        expect(dataSafety.totalAudits, 1);
      },
    );
  });
}
