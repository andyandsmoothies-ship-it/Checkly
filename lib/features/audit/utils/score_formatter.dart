/// Pure Dart utility for converting raw scoring data into a human-readable
/// display string.  Zero Flutter / widget dependencies — safe to unit-test
/// without a widget tree.
class ScoreFormatter {
  static String format({
    required String? scoringMode,
    double? rawEarned,
    double? rawMax,
    double? totalScore,
    bool? isWeighted,
  }) {
    if (scoringMode == 'survey') return '';

    if (scoringMode == 'accumulation') {
      if (rawEarned != null && rawMax != null) {
        return '${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} pts';
      }
      return totalScore != null ? '${_fmtPct(totalScore)}%' : '—';
    }

    if (scoringMode == 'checklist') {
      return totalScore != null ? '${_fmtPts(totalScore)} / 100 pts' : '—';
    }

    // penalty or unknown / null mode
    return totalScore != null ? '${_fmtPct(totalScore)}%' : '—';
  }

  /// Formats a points value — whole numbers show no decimal, fractional show 1 dp.
  static String _fmtPts(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Formats a percentage value — same rule as points.
  static String _fmtPct(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
