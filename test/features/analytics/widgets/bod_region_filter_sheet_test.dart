import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:checkly/features/analytics/widgets/bod_region_filter_sheet.dart';
import 'package:checkly/features/analytics/manager/bod_analytics_manager.dart';

class MockBodAnalyticsManager extends Mock implements BodAnalyticsManager {}

void main() {
  late MockBodAnalyticsManager mockManager;

  setUp(() {
    mockManager = MockBodAnalyticsManager();
    when(() => mockManager.addListener(any())).thenReturn(null);
    when(() => mockManager.removeListener(any())).thenReturn(null);
    when(() => mockManager.isLiveMode).thenReturn(false);
    when(() => mockManager.activeProvince).thenReturn(null);
    when(() => mockManager.activeDistrict).thenReturn(null);
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BodRegionFilterSheet(manager: mockManager),
                );
              },
              child: const Text('Open Filter'),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'renders filter sheet and initializes with empty active filters',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open Bottom Sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Region'), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('Nightly Snapshot'), findsOneWidget);

      // Apply button should be disabled because province/district are null
      final applyButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Apply Filter'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(applyButton.onPressed, isNull);
    },
  );

  testWidgets(
    'enables Apply button when province and district are selected, and calls applyFilter',
    (tester) async {
      when(
        () => mockManager.applyFilter(any(), any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());

      // Open Bottom Sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Select Province dropdown item 'Hanoi'
      // Find Province input decorator dropdown button
      await tester.tap(find.text('All Provinces'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hanoi').last);
      await tester.pumpAndSettle();

      // Select District dropdown item 'Ba Dinh'
      await tester.tap(find.text('All Districts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ba Dinh').last);
      await tester.pumpAndSettle();

      // Apply button should now be enabled
      final applyButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Apply Filter'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(applyButton.onPressed, isNotNull);

      // Tap Apply Filter
      await tester.tap(find.text('Apply Filter'));
      await tester.pumpAndSettle();

      verify(() => mockManager.applyFilter('Hanoi', 'Ba Dinh')).called(1);
      // Modal sheet should be closed
      expect(find.text('Filter Region'), findsNothing);
    },
  );

  testWidgets('calls clearFilter when Clear button is pressed', (tester) async {
    when(() => mockManager.clearFilter()).thenAnswer((_) async {});
    when(() => mockManager.activeProvince).thenReturn('Hanoi');
    when(() => mockManager.activeDistrict).thenReturn('Dong Da');

    await tester.pumpWidget(buildTestWidget());

    // Open Bottom Sheet
    await tester.tap(find.text('Open Filter'));
    await tester.pumpAndSettle();

    expect(find.text('Clear'), findsOneWidget);

    // Tap Clear
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    verify(() => mockManager.clearFilter()).called(1);
    // Modal sheet should be closed
    expect(find.text('Filter Region'), findsNothing);
  });
}
