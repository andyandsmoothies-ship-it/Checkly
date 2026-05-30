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
    bool shortForm = false,
  }) {
    if (scoringMode == 'survey') return '—';

    if (scoringMode == 'accumulation') {
      if (totalScore == null) return '—';
      if (shortForm) return _fmtPct(totalScore);
      if (rawEarned != null && rawMax != null) {
        return '${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)';
      }
      return '${_fmtPct(totalScore)}%';
    }

    if (scoringMode == 'checklist') {
      if (shortForm) {
        return totalScore != null ? _fmtPts(totalScore) : '—';
      }
      return totalScore != null ? '${_fmtPts(totalScore)} / 100 pts' : '—';
    }

    // penalty or unknown / null mode
    if (totalScore == null) return '—';
    if (!shortForm &&
        isWeighted == true &&
        rawEarned != null &&
        rawMax != null) {
      return '${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)';
    }
    return _fmtPct(totalScore);
  }

  /// Formats a points value — whole numbers show no decimal, fractional show 1 dp.
  static String _fmtPts(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Formats a percentage value — same rule as points.
  static String _fmtPct(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
