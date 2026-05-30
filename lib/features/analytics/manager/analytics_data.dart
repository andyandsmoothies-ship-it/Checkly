import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';

/// Pure data classes for the Analytics feature.
/// Extracted from analytics_manager.dart to keep file size under 250 lines.

// ─── ActionableInsight ────────────────────────────────────────────────────────

class ActionableInsight {
  final String id;
  final String type; // 'warning' | 'info' | 'positive'
  final String title;
  final String description;

  const ActionableInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
  });

  factory ActionableInsight.fromJson(Map<String, dynamic> json) {
    return ActionableInsight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}

// ─── RadarData ────────────────────────────────────────────────────────────────

class RadarData {
  final List<String> categories;
  final List<double> storeValues;
  final List<double> regionalValues;

  const RadarData({
    required this.categories,
    required this.storeValues,
    required this.regionalValues,
  });

  factory RadarData.fromJson(Map<String, dynamic> radarJson) {
    return RadarData(
      categories: (radarJson['categories'] as List).cast<String>(),
      storeValues: (radarJson['storeScores'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList(),
      regionalValues: (radarJson['areaScores'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList(),
    );
  }
}

// ─── AnalyticsData ────────────────────────────────────────────────────────────

/// Holds the fully-computed analytics snapshot after a [load] call.
class AnalyticsData {
  final int totalAudits;
  final double avgScore;
  final int openAPs;
  final int overdueAPs;
  final double completionRate;
  final List<TrendPoint> trend;
  final List<CategoryScore> categoryScores;
  final List<String> storeNames;
  final List<String> templateTypes;
  final List<String> provinceNames;
  final List<String> auditorNames;
  final List<String> categoryTagNames;
  final List<ActionableInsight> insights;
  final RadarData? radarData;
  final bool insightsStale;

  const AnalyticsData({
    required this.totalAudits,
    required this.avgScore,
    required this.openAPs,
    required this.overdueAPs,
    required this.completionRate,
    required this.trend,
    required this.categoryScores,
    required this.storeNames,
    required this.templateTypes,
    required this.provinceNames,
    required this.auditorNames,
    this.categoryTagNames = const [],
    this.insights = const [],
    this.radarData,
    this.insightsStale = false,
  });
}
