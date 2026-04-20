class SurveyQuestionResult {
  final String? criterionId;
  final String label;
  final int totalResponses;
  final List<SurveyOptionCount> options;

  const SurveyQuestionResult({
    this.criterionId,
    required this.label,
    required this.totalResponses,
    required this.options,
  });

  factory SurveyQuestionResult.fromJson(Map<String, dynamic> json) =>
      SurveyQuestionResult(
        criterionId: json['criterionId'] as String?,
        label: json['label'] as String? ?? 'Unknown',
        totalResponses: json['totalResponses'] as int? ?? 0,
        options:
            (json['options'] as List<dynamic>?)
                ?.map(
                  (o) => SurveyOptionCount.fromJson(o as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class SurveyOptionCount {
  final String value;
  final int count;
  final double percentage;

  const SurveyOptionCount({
    required this.value,
    required this.count,
    required this.percentage,
  });

  factory SurveyOptionCount.fromJson(Map<String, dynamic> json) =>
      SurveyOptionCount(
        value: json['value'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}
