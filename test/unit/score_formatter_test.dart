import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/utils/score_formatter.dart';

void main() {
  group('ScoreFormatter — accumulation branch', () {
    test('TC-01: Accumulation OFF — Long Form with Raw Points', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: false,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );

      // Assert
      expect(result, '80% (100 / 110 raw pts)');
    });

    test('TC-02: Accumulation ON (Weighted) — Long Form with Raw Points', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: true,
        shortForm: false,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );

      // Assert
      expect(result, '80% (100 / 110 raw pts)');
    });

    test('TC-03: Accumulation OFF — Short Form (List Badge)', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: true,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );

      // Assert
      expect(result, '80');
    });

    test('TC-04: Accumulation ON — Short Form (List Badge)', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: true,
        shortForm: true,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );

      // Assert
      expect(result, '80');
    });

    test('TC-05: Accumulation — Long Form, No Raw Data Available', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: false,
        rawEarned: null,
        rawMax: null,
        totalScore: 80,
      );

      // Assert
      expect(result, '80%');
    });

    test('TC-06: Accumulation — Null Score → Dash', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        totalScore: null,
      );

      // Assert
      expect(result, '—');
    });

    test('TC-07: Accumulation — Decimal Score, Decimal Raw Points', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: false,
        rawEarned: 50.5,
        rawMax: 110,
        totalScore: 45.9,
      );

      // Assert
      expect(result, '45.9% (50.5 / 110 raw pts)');
    });

    test('TC-08: Accumulation — Perfect Score', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: false,
        rawEarned: 100,
        rawMax: 100,
        totalScore: 100,
      );

      // Assert
      expect(result, '100% (100 / 100 raw pts)');
    });
  });

  group('ScoreFormatter — regression checks', () {
    test('TC-09 (Regression): Penalty + Weighted + Long Form — Unchanged', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'penalty',
        isWeighted: true,
        shortForm: false,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );

      // Assert
      expect(result, '80% (100 / 110 raw pts)');
    });

    test(
      'TC-10 (Regression): Penalty + Unweighted + Long Form — Unchanged',
      () {
        // Act
        final result = ScoreFormatter.format(
          scoringMode: 'penalty',
          isWeighted: false,
          shortForm: false,
          rawEarned: null,
          rawMax: null,
          totalScore: 80,
        );

        // Assert
        expect(result, '80');
      },
    );

    test('TC-11 (Regression): Checklist — Long Form Unchanged', () {
      // Act
      final result = ScoreFormatter.format(
        scoringMode: 'checklist',
        shortForm: false,
        totalScore: 80,
      );

      // Assert
      expect(result, '80 / 100 pts');
    });

    test('TC-12 (Regression): Survey — Always Dash', () {
      // Act
      final result = ScoreFormatter.format(scoringMode: 'survey');

      // Assert
      expect(result, '—');
    });
  });
}
