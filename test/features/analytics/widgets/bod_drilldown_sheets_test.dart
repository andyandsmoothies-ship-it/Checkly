import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/analytics/widgets/bod_store_detail_sheet.dart';
import 'package:checkly/features/analytics/widgets/bod_category_detail_sheet.dart';
import 'package:checkly/features/analytics/widgets/bod_kpi_grid.dart';
import 'package:checkly/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_data.dart';
import 'package:checkly/_shared/widgets/primitives/pill_chip.dart';

class MockBodAnalyticsManager extends Mock implements BodAnalyticsManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(BodAgingBucket.all);
  });

  late MockBodAnalyticsManager mockManager;

  setUp(() {
    mockManager = MockBodAnalyticsManager();
    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
  });

  Widget buildTestWidget(
    Widget child, {
    double height = 600.0,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: Size(400.0, height),
            disableAnimations: disableAnimations,
          ),
          child: Builder(
            builder: (context) {
              return child;
            },
          ),
        ),
      ),
    );
  }

  group('BodStoreDetailSheet TDD Tests', () {
    testWidgets('C3-TEST-01: Store Detail Mount & Loader Initiation', (
      tester,
    ) async {
      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(true);
      when(() => mockManager.storeDetail).thenReturn(null);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
        ),
      );

      verify(() => mockManager.loadStoreDetail('s-1')).called(1);
    });

    testWidgets('C3-TEST-02: Skeleton Shimmer & Motion Compliance', (
      tester,
    ) async {
      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(true);
      when(() => mockManager.storeDetail).thenReturn(null);
      when(() => mockManager.error).thenReturn(null);

      // Verify normal loading skeletons
      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
        ),
      );
      expect(
        find.byType(SizedBox),
        findsWidgets,
      ); // Standard skeleton uses boxes/shimmer

      // Verify reduced motion compliance (should not crash and displays skeletons static)
      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('C3-TEST-03: Store Detail Success Rendering', (tester) async {
      final mockData = StoreBodSummary(
        storeName: 'Airport Express',
        recentAudits: [
          RecentAuditEntry(
            date: '2026-05-24T14:30:00Z',
            score: 58.4,
            auditorName: 'Alice',
          ),
        ],
        categoryBreakdown: [
          CategoryScoreEntry(categoryName: 'Food Safety', avgScore: 62.5),
        ],
      );

      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(false);
      when(() => mockManager.storeDetail).thenReturn(mockData);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
        ),
      );

      expect(find.text('Airport Express'), findsOneWidget);
      expect(find.textContaining('Live data as of'), findsOneWidget);
      expect(find.text('Food Safety'), findsOneWidget);
      expect(find.text('58.4%'), findsOneWidget); // Score format
    });

    testWidgets('C3-TEST-04: Store Detail Empty State', (tester) async {
      final mockData = StoreBodSummary(
        storeName: 'Empty Store',
        recentAudits: [],
        categoryBreakdown: [],
      );

      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(false);
      when(() => mockManager.storeDetail).thenReturn(mockData);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
        ),
      );

      expect(find.text('No audit history available'), findsOneWidget);
    });

    testWidgets('C3-TEST-09: Store Detail Regional Benchmarking and SLA Overdue success rendering', (tester) async {
      final mockData = StoreBodSummary(
        storeName: 'Airport Express',
        recentAudits: [
          RecentAuditEntry(
            date: '2026-05-24T14:30:00Z',
            score: 85.0,
            auditorName: 'Alice',
          ),
        ],
        categoryBreakdown: [
          CategoryScoreEntry(categoryName: 'Food Safety', avgScore: 62.5),
        ],
        quartileLabel: 'Top 25% in Region',
        regionalAvgScore: 80.0,
        slaOverdueBuckets: [
          SlaOverdueSegment(bucket: '0-7 Days', count: 2),
          SlaOverdueSegment(bucket: '8-30 Days', count: 1),
          SlaOverdueSegment(bucket: '31+ Days', count: 0),
        ],
      );

      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(false);
      when(() => mockManager.storeDetail).thenReturn(mockData);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
        ),
      );

      expect(find.text('Regional Benchmarking'), findsOneWidget);
      expect(find.text('Top 25% in Region'), findsOneWidget);
      expect(find.text('Regional Avg: 80.0%'), findsOneWidget);
      expect(find.text('5.0% above regional average'), findsOneWidget);

      expect(find.text('SLA Overdue Action Plans'), findsOneWidget);
      expect(find.text('0-7 Days'), findsOneWidget);
      expect(find.text('8-30 Days'), findsOneWidget);
      expect(find.text('31+ Days'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('BodCategoryDetailSheet TDD Tests', () {
    testWidgets('C3-TEST-05: Category Detail Mount & Loader Initiation', (
      tester,
    ) async {
      when(
        () => mockManager.loadCategoryDetail(any()),
      ).thenAnswer((_) async {});
      when(() => mockManager.isCategoryDetailLoading).thenReturn(true);
      when(() => mockManager.categoryDetail).thenReturn([]);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodCategoryDetailSheet(
            categoryName: 'Food Safety',
            manager: mockManager,
          ),
        ),
      );

      verify(() => mockManager.loadCategoryDetail('Food Safety')).called(1);
    });

    testWidgets('C3-TEST-06: Category Detail Worst-Store Sorting', (
      tester,
    ) async {
      final mockData = [
        CategoryStoreEntry(
          storeName: 'Store A',
          avgScore: 85.0,
          auditCount: 2,
          failureCount: 0,
        ),
        CategoryStoreEntry(
          storeName: 'Store B',
          avgScore: 42.0,
          auditCount: 2,
          failureCount: 1,
        ),
        CategoryStoreEntry(
          storeName: 'Store C',
          avgScore: 60.0,
          auditCount: 3,
          failureCount: 0,
        ),
      ];

      when(
        () => mockManager.loadCategoryDetail(any()),
      ).thenAnswer((_) async {});
      when(() => mockManager.isCategoryDetailLoading).thenReturn(false);
      when(() => mockManager.categoryDetail).thenReturn(mockData);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodCategoryDetailSheet(
            categoryName: 'Food Safety',
            manager: mockManager,
          ),
        ),
      );

      expect(find.text('Store B'), findsOneWidget);
      expect(find.text('Store C'), findsOneWidget);
      expect(find.text('Store A'), findsOneWidget);

      // Verify Sorting order (worst store first: Store B -> Store C -> Store A)
      final storeBPos = tester.getCenter(find.text('Store B')).dy;
      final storeCPos = tester.getCenter(find.text('Store C')).dy;
      final storeAPos = tester.getCenter(find.text('Store A')).dy;

      expect(storeBPos < storeCPos, isTrue);
      expect(storeCPos < storeAPos, isTrue);
    });

    testWidgets('C3-TEST-07: Category Detail Empty State', (tester) async {
      when(
        () => mockManager.loadCategoryDetail(any()),
      ).thenAnswer((_) async {});
      when(() => mockManager.isCategoryDetailLoading).thenReturn(false);
      when(() => mockManager.categoryDetail).thenReturn([]);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodCategoryDetailSheet(
            categoryName: 'Food Safety',
            manager: mockManager,
          ),
        ),
      );

      expect(find.text('No store data for this category'), findsOneWidget);
    });
  });

  group('Shared Bottom Sheet Constraints', () {
    testWidgets('C3-TEST-08: Max Height Constraint Guard (Store)', (
      tester,
    ) async {
      final mockData = StoreBodSummary(
        storeName: 'Airport Express',
        recentAudits: [],
        categoryBreakdown: [],
      );

      when(() => mockManager.loadStoreDetail(any())).thenAnswer((_) async {});
      when(() => mockManager.isStoreDetailLoading).thenReturn(false);
      when(() => mockManager.storeDetail).thenReturn(mockData);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodStoreDetailSheet(storeId: 's-1', manager: mockManager),
          height: 800.0,
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(BodStoreDetailSheet),
              matching: find.byWidgetPredicate(
                (w) => w is ConstrainedBox && w.constraints.maxHeight > 0,
              ),
            )
            .first,
      );
      expect(constrainedBox.constraints.maxHeight, equals(800.0 * 0.85));
    });

    testWidgets('C3-TEST-08: Max Height Constraint Guard (Category)', (
      tester,
    ) async {
      when(
        () => mockManager.loadCategoryDetail(any()),
      ).thenAnswer((_) async {});
      when(() => mockManager.isCategoryDetailLoading).thenReturn(false);
      when(() => mockManager.categoryDetail).thenReturn([]);
      when(() => mockManager.error).thenReturn(null);

      await tester.pumpWidget(
        buildTestWidget(
          BodCategoryDetailSheet(
            categoryName: 'Food Safety',
            manager: mockManager,
          ),
          height: 800.0,
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(BodCategoryDetailSheet),
              matching: find.byWidgetPredicate(
                (w) => w is ConstrainedBox && w.constraints.maxHeight > 0,
              ),
            )
            .first,
      );
      expect(constrainedBox.constraints.maxHeight, equals(800.0 * 0.85));
    });
  });

  group('BodKpiGrid TDD Tests', () {
    testWidgets(
      'C4-TEST-01: BodKpiGrid displays open/overdue AP count and opens sheet on tap',
      (tester) async {
        when(() => mockManager.loadApDetails(any())).thenAnswer((_) async {});
        when(() => mockManager.isApDetailLoading).thenReturn(true);
        when(() => mockManager.apDetails).thenReturn([]);
        when(() => mockManager.error).thenReturn(null);

        final chainKpis = {
          'totalAudits': 150,
          'avgScore': 78.5,
          'completionRate': 92.0,
          'completionRateDelta': 1.5,
          'openAPs': 12,
          'overdueAPs': 3,
        };

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        // Check text is rendered
        expect(find.text('3 / 12'), findsOneWidget);
        expect(find.text('Overdue / Open APs'), findsOneWidget);

        // Tap card
        await tester.tap(find.text('Overdue / Open APs'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify it opens BodApBucketDetailSheet and calls loadApDetails(BodAgingBucket.all)
        expect(find.byType(BodApBucketDetailSheet), findsOneWidget);
        verify(() => mockManager.loadApDetails(BodAgingBucket.all)).called(1);
      },
    );

    testWidgets(
      'C4-TEST-02: BodKpiGrid displays active stores and total auditors counts',
      (tester) async {
        final chainKpis = {
          'totalAudits': 150,
          'avgScore': 78.5,
          'completionRate': 92.0,
          'completionRateDelta': 1.5,
          'openAPs': 12,
          'overdueAPs': 3,
          'activeStores': 45,
          'totalAuditors': 14,
        };

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        // Check active stores card
        expect(find.text('Active Stores'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);

        // Check total auditors card
        expect(find.text('Total Auditors'), findsOneWidget);
        expect(find.text('14'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-S2-01: BodKpiGrid displays Avg TTR Days and a non-zero value format',
      (tester) async {
        final chainKpis = {
          'totalAudits': 150,
          'avgScore': 78.5,
          'completionRate': 92.0,
          'openAPs': 12,
          'overdueAPs': 3,
          'activeStores': 45,
          'totalAuditors': 14,
          'avgTtrDays': 4.2,
        };

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        expect(find.text('Avg TTR Days'), findsOneWidget);
        expect(find.text('4.2 days'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-S2-02: BodKpiGrid displays N/A when avgTtrDays is exactly 0.0',
      (tester) async {
        final chainKpis = {
          'totalAudits': 150,
          'avgScore': 78.5,
          'completionRate': 92.0,
          'openAPs': 12,
          'overdueAPs': 3,
          'activeStores': 45,
          'totalAuditors': 14,
          'avgTtrDays': 0.0,
        };

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        expect(find.text('Avg TTR Days'), findsOneWidget);
        expect(find.text('N/A'), findsOneWidget);
        expect(find.text('0.0 days'), findsNothing);
      },
    );

    testWidgets(
      'TC-S2-03: BodKpiGrid displays correct colored PillChips for different TTR limits',
      (tester) async {
        // Test Green: <= 7.0
        final greenKpis = {'avgTtrDays': 5.0};
        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: greenKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is PillChip && widget.type == PillChipType.green,
          ),
          findsOneWidget,
        );

        // Test Yellow: <= 14.0
        final yellowKpis = {'avgTtrDays': 10.0};
        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: yellowKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is PillChip && widget.type == PillChipType.yellow,
          ),
          findsOneWidget,
        );

        // Test Red: > 14.0
        final redKpis = {'avgTtrDays': 15.0};
        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: redKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is PillChip && widget.type == PillChipType.red,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-S2-06: BodKpiGrid treats negative avgTtrDays value as 0.0 and shows N/A',
      (tester) async {
        final chainKpis = {'avgTtrDays': -3.5};

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        expect(find.text('Avg TTR Days'), findsOneWidget);
        expect(find.text('N/A'), findsOneWidget);
        expect(find.text('-3.5 days'), findsNothing);
      },
    );

    testWidgets(
      'TC-S2-07: BodKpiGrid with extremely large value handles layouts cleanly at 400px width',
      (tester) async {
        final chainKpis = {'avgTtrDays': 999.9};

        await tester.pumpWidget(
          buildTestWidget(
            BodKpiGrid(
              chainKpis: chainKpis,
              trend: const [],
              manager: mockManager,
            ),
            disableAnimations: true,
          ),
        );

        expect(find.text('Avg TTR Days'), findsOneWidget);
        expect(find.text('999.9 days'), findsOneWidget);
        // No layout exceptions are thrown under the test framework, proving layout robustness.
      },
    );
  });
}
