class TrendUtils {
  static double calculateSMA3(List<double> scores, int index) {
    if (scores.isEmpty) {
      return 0.0;
    }
    if (index < 2) {
      return scores[index];
    }
    return (scores[index] + scores[index - 1] + scores[index - 2]) / 3.0;
  }
}
