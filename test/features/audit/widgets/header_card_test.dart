import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/widgets/header_card.dart';
import 'package:checkly/features/audit/model/submission_detail_dto.dart';

void main() {
  group('HeaderCard Widget Tests', () {
    testWidgets('Renders info row when isWeighted is true', (tester) async {
      final detail = SubmissionDetailDto(
        id: 's1',
        templateTitle: 'Weekly Kitchen Audit',
        storeName: 'Store 101',
        auditorName: 'John Doe',
        status: 'completed',
        totalScore: 92.5,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        answers: [],
        isWeighted: true,
        scoringMode: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderCard(detail: detail, scoringMode: 'up'),
          ),
        ),
      );

      // Assert info row elements are present
      expect(
        find.text('Final score is weighted based on section importance.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Hides info row when isWeighted is false', (tester) async {
      final detail = SubmissionDetailDto(
        id: 's2',
        templateTitle: 'Weekly Kitchen Audit',
        storeName: 'Store 101',
        auditorName: 'John Doe',
        status: 'completed',
        totalScore: 92.5,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        answers: [],
        isWeighted: false,
        scoringMode: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderCard(detail: detail, scoringMode: 'up'),
          ),
        ),
      );

      // Assert info row elements are not present
      expect(
        find.text('Final score is weighted based on section importance.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('Hides info row when isWeighted is null', (tester) async {
      final detail = SubmissionDetailDto(
        id: 's3',
        templateTitle: 'Weekly Kitchen Audit',
        storeName: 'Store 101',
        auditorName: 'John Doe',
        status: 'completed',
        totalScore: 92.5,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        answers: [],
        isWeighted: null,
        scoringMode: 'up',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderCard(detail: detail, scoringMode: 'up'),
          ),
        ),
      );

      // Assert info row elements are not present
      expect(
        find.text('Final score is weighted based on section importance.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('Renders Area Manager and Store Manager info rows when present', (tester) async {
      final detail = SubmissionDetailDto(
        id: 's4',
        templateTitle: 'Weekly Kitchen Audit',
        storeName: 'Store 101',
        auditorName: 'John Doe',
        status: 'completed',
        totalScore: 92.5,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        answers: [],
        isWeighted: false,
        scoringMode: 'up',
        areaManagerName: 'Alice Smith',
        storeManagerName: 'Bob Jones',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderCard(detail: detail, scoringMode: 'up'),
          ),
        ),
      );

      expect(find.text('Area Manager: Alice Smith'), findsOneWidget);
      expect(find.text('Store Manager: Bob Jones'), findsOneWidget);
      expect(find.byIcon(Icons.supervised_user_circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    });

    testWidgets('Hides Area Manager and Store Manager info rows when they are null', (tester) async {
      final detail = SubmissionDetailDto(
        id: 's5',
        templateTitle: 'Weekly Kitchen Audit',
        storeName: 'Store 101',
        auditorName: 'John Doe',
        status: 'completed',
        totalScore: 92.5,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        answers: [],
        isWeighted: false,
        scoringMode: 'up',
        areaManagerName: null,
        storeManagerName: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderCard(detail: detail, scoringMode: 'up'),
          ),
        ),
      );

      expect(find.textContaining('Area Manager:'), findsNothing);
      expect(find.textContaining('Store Manager:'), findsNothing);
      expect(find.byIcon(Icons.supervised_user_circle_outlined), findsNothing);
      expect(find.byIcon(Icons.badge_outlined), findsNothing);
    });
  });
}
