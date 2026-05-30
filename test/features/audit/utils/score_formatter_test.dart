import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/utils/score_formatter.dart';

void main() {
  group('ScoreFormatter.format() Tests', () {
    test('TC-S2-01: ScoreFormatter_Accumulation_WithRawFields_ShowsPoints', () {
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        rawEarned: 10,
        rawMax: 15,
        totalScore: 66.7,
      );
      expect(result, '66.7% (10 / 15 raw pts)');
    });

    test(
      'TC-S2-02: ScoreFormatter_Accumulation_NullRawFields_FallsBackToPercent',
      () {
        final result = ScoreFormatter.format(
          scoringMode: 'accumulation',
          rawEarned: null,
          rawMax: null,
          totalScore: 66.7,
        );
        expect(result, '66.7%');
      },
    );

    test('TC-S2-03: ScoreFormatter_Checklist_ShowsOutOf100', () {
      final result = ScoreFormatter.format(
        scoringMode: 'checklist',
        rawEarned: null,
        rawMax: null,
        totalScore: 90,
      );
      expect(result, '90 / 100 pts');
    });

    test('TC-S2-04: ScoreFormatter_Penalty_ShowsPercent', () {
      final result = ScoreFormatter.format(
        scoringMode: 'penalty',
        isWeighted: true,
        totalScore: 85,
      );
      expect(result, '85');
    });

    test('TC-S2-05: ScoreFormatter_Survey_ReturnsDash', () {
      final result = ScoreFormatter.format(
        scoringMode: 'survey',
        totalScore: null,
      );
      expect(result, '—');
    });

    test('TC-S2-06: ScoreFormatter_NullMode_FallsBackToPercent', () {
      final result = ScoreFormatter.format(scoringMode: null, totalScore: 66.7);
      expect(result, '66.7');
    });

    test('TC-S2-07: ScoreFormatter_NullTotalScore_ReturnsDash', () {
      final result = ScoreFormatter.format(
        scoringMode: 'penalty',
        totalScore: null,
      );
      expect(result, '—');
    });

    test('TC-S2-08: ScoreFormatter_Accumulation_ZeroPoints_ShowsZeroOutOf', () {
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        rawEarned: 0,
        rawMax: 15,
        totalScore: 0,
      );
      expect(result, '0% (0 / 15 raw pts)');
    });

    test('TC-S2-09: ScoreFormatter_Checklist_WholeNumber_NoDecimal', () {
      final result = ScoreFormatter.format(
        scoringMode: 'checklist',
        totalScore: 90.0,
      );
      expect(result, '90 / 100 pts');
    });

    test('TC-S2-10: ScoreFormatter_Penalty_OneDecimalPlace', () {
      final result = ScoreFormatter.format(
        scoringMode: 'penalty',
        totalScore: 85.5,
      );
      expect(result, '85.5');
    });

    test(
      'TC-S2-11: ScoreFormatter_Penalty_Weighted_Detailed_ShowsRawPoints',
      () {
        final result = ScoreFormatter.format(
          scoringMode: 'penalty',
          isWeighted: true,
          totalScore: 85.0,
          rawEarned: 120.0,
          rawMax: 150.0,
          shortForm: false,
        );
        expect(result, '85% (120 / 150 raw pts)');
      },
    );

    test(
      'TC-S2-12: ScoreFormatter_Penalty_Weighted_ShortForm_ShowsPercentOnly',
      () {
        final result = ScoreFormatter.format(
          scoringMode: 'penalty',
          isWeighted: true,
          totalScore: 85.0,
          rawEarned: 120.0,
          rawMax: 150.0,
          shortForm: true,
        );
        expect(result, '85');
      },
    );
  });
}
