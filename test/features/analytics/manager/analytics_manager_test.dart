import 'package:checkly/_shared/database/app_database.dart';
import 'package:checkly/features/analytics/manager/analytics_manager.dart';
import 'package:checkly/features/analytics/services/analytics_api_service.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalyticsApiService extends Mock implements AnalyticsApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late AnalyticsManager manager;
  late MockAnalyticsApiService mockApi;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('SELECT 1'); // force lazy init

    mockApi = MockAnalyticsApiService();

    // Default fallback to offline so existing tests pass
    when(
      () => mockApi.getAnalytics(
        storeId: any(named: 'storeId'),
        areaId: any(named: 'areaId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenThrow(
      DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ''),
      ),
    );

    manager = AnalyticsManager(db: db, apiService: mockApi);
  });

  tearDown(() async {
    await db.close();
  });

  test('AnalyticsManager computes basic KPIs from empty DB', () async {
    await manager.load();

    expect(manager.isLoading, false);
    expect(manager.error, isNull);
    expect(manager.data, isNotNull);

    final data = manager.data!;
    expect(data.totalAudits, 0);
    expect(data.avgScore, 0.0);
    expect(data.openAPs, 0);
    expect(data.overdueAPs, 0);
    expect(data.completionRate, 0.0);
  });

  test('AnalyticsManager computes KPIs accurately from populated DB', () async {
    final now = DateTime.now();

    // Seed templates
    await db
        .into(db.cachedTemplates)
        .insert(
          CachedTemplatesCompanion.insert(
            id: 't1',
            title: 'Food Safety',
            type: 'food_safety',
            version: const Value(1),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Seed stores
    await db
        .into(db.cachedStores)
        .insert(
          CachedStoresCompanion.insert(
            id: 's1',
            name: 'Store A',
            areaId: const Value('a1'),
            areaName: const Value('North Area'),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Seed submissions
    await db
        .into(db.cachedSubmissions)
        .insert(
          CachedSubmissionsCompanion.insert(
            id: 'sub1',
            templateId: const Value('t1'),
            storeId: const Value('s1'),
            storeName: const Value('Store A'),
            auditorId: const Value('u1'),
            auditorName: const Value('Auditor John'),
            status: 'completed',
            totalScore: const Value(85.0),
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        );

    await db
        .into(db.cachedSubmissions)
        .insert(
          CachedSubmissionsCompanion.insert(
            id: 'sub2',
            templateId: const Value('t1'),
            storeId: const Value('s1'),
            storeName: const Value('Store A'),
            auditorId: const Value('u1'),
            auditorName: const Value('Auditor John'),
            status: 'in_progress',
            totalScore: const Value(45.0),
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        );

    // Seed Action Plans
    await db
        .into(db.cachedActionPlans)
        .insert(
          CachedActionPlansCompanion.insert(
            id: 'ap1',
            criteriaLabel: 'Fix oven',
            groupTitle: 'Kitchen',
            status: const Value('open'),
            deadline: Value(now.subtract(const Duration(days: 1))), // overdue
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.cachedActionPlans)
        .insert(
          CachedActionPlansCompanion.insert(
            id: 'ap2',
            criteriaLabel: 'Clean floor',
            groupTitle: 'Dining',
            status: const Value('open'),
            deadline: Value(now.add(const Duration(days: 5))), // not overdue
            createdAt: now,
            updatedAt: now,
          ),
        );

    await manager.load();

    expect(manager.error, isNull);
    expect(manager.data, isNotNull);
    final data = manager.data!;

    expect(data.totalAudits, 2);
    expect(data.avgScore, 65.0); // (85 + 45) / 2
    expect(data.completionRate, 50.0); // 1 / 2 * 100

    expect(data.openAPs, 2);
    expect(data.overdueAPs, 1);

    expect(data.storeNames, ['Store A']);
    expect(data.areaNames, ['North Area']);
    expect(data.templateTypes, ['food_safety']);
    expect(data.auditorNames, ['Auditor John']);

    // Check trend and category mapping
    expect(data.categoryScores.length, 1);
    expect(data.categoryScores.first.name, 'food_safety');
    expect(data.categoryScores.first.avgScore, 65.0);
  });

  test('AnalyticsManager applies filters correctly', () async {
    final now = DateTime.now();

    await db
        .into(db.cachedStores)
        .insert(
          CachedStoresCompanion.insert(
            id: 's1',
            name: 'Store A',
            areaName: const Value('North'),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.cachedStores)
        .insert(
          CachedStoresCompanion.insert(
            id: 's2',
            name: 'Store B',
            areaName: const Value('South'),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.cachedSubmissions)
        .insert(
          CachedSubmissionsCompanion.insert(
            id: 'sub1',
            templateId: const Value('t1'),
            storeId: const Value('s1'),
            storeName: const Value('Store A'),
            auditorId: const Value('u1'),
            status: 'completed',
            totalScore: const Value(100.0),
            createdAt: now,
          ),
        );
    await db
        .into(db.cachedSubmissions)
        .insert(
          CachedSubmissionsCompanion.insert(
            id: 'sub2',
            templateId: const Value('t1'),
            storeId: const Value('s2'),
            storeName: const Value('Store B'),
            auditorId: const Value('u1'),
            status: 'completed',
            totalScore: const Value(50.0),
            createdAt: now,
          ),
        );

    // Filter by area
    manager.selectedArea = 'South';
    await manager.load();

    expect(manager.data!.totalAudits, 1);
    expect(manager.data!.avgScore, 50.0);

    // Filter by store
    manager.selectedArea = null;
    manager.selectedStore = 'Store A';
    await manager.load();

    expect(manager.data!.totalAudits, 1);
    expect(manager.data!.avgScore, 100.0);
  });

  test(
    'AR-01: AnalyticsManager online path - calls API and maps response',
    () async {
      when(
        () => mockApi.getAnalytics(
          storeId: any(named: 'storeId'),
          areaId: any(named: 'areaId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => {
          'totalAudits': 14,
          'avgScore': 85.5,
          'openAPs': 3,
          'overdueAPs': 1,
          'completionRate': 92.5,
          'trend': [
            {'month': '2026-01', 'avgScore': 82.0, 'count': 4},
            {'month': '2026-02', 'avgScore': 85.5, 'count': 5},
          ],
          'categoryScores': [
            {'name': 'Safety', 'avgScore': 78.0, 'auditCount': 6},
          ],
          'insightsStale': false,
          'insights': [
            {
              'id': '1',
              'type': 'warning',
              'title': 'Score dropped',
              'description': 'Recent audit score dropped significantly',
            }
          ],
          'radarData': {
            'categories': ['A', 'B', 'C'],
            'storeScores': [90.0, 80.0, 70.0],
            'areaScores': [85.0, 75.0, 65.0]
          },
        },
      );

      await manager.load();

      expect(manager.isOffline, false);
      expect(manager.data, isNotNull);
      final data = manager.data!;

      expect(data.totalAudits, 14);
      expect(data.avgScore, 85.5);
      expect(data.openAPs, 3);
      expect(data.overdueAPs, 1);
      expect(data.completionRate, 92.5);
      expect(data.trend.length, 2);
      expect(data.categoryScores.length, 1);
      expect(data.insightsStale, false);
      expect(data.insights.length, 1);
      expect(data.insights[0].type, 'warning');
      expect(data.insights[0].title, 'Score dropped');
      expect(data.insights[0].description, 'Recent audit score dropped significantly');
      expect(data.radarData, isNotNull);
      expect(data.radarData!.categories, ['A', 'B', 'C']);
      expect(data.radarData!.storeValues, [90.0, 80.0, 70.0]);
      expect(data.radarData!.regionalValues, [85.0, 75.0, 65.0]);
    },
  );

  test(
    'AR-02: AnalyticsManager offline path - DioException triggers Drift fallback',
    () async {
      final now = DateTime.now();
      await db
          .into(db.cachedSubmissions)
          .insert(
            CachedSubmissionsCompanion.insert(
              id: 'sub1',
              templateId: const Value('t1'),
              storeId: const Value('s1'),
              storeName: const Value('Store A'),
              auditorId: const Value('u1'),
              status: 'completed',
              totalScore: const Value(100.0),
              createdAt: now,
            ),
          );

      // The setUp block already configures the mock to throw DioException.
      await manager.load();

      expect(manager.isOffline, true);
      expect(manager.data, isNotNull);
      final data = manager.data!;

      expect(data.totalAudits, 1);
      expect(data.avgScore, 100.0);
    },
  );
}
