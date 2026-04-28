import '../model/submission_answer_input.dart';

/// In-progress answer entry for the audit form.
class AuditAnswer {
  final String criteriaId;
  String? value; // 'conform', 'non_conform', 'na'
  double? numericValue; // fault count
  String? note;
  String? photoUrl;
  int repeatedFaultCount;
  bool isCcp;
  bool isRisk;

  /// Derived from repeatedFaultCount for backward compatibility.
  bool get isRepeatedError => repeatedFaultCount > 0;

  AuditAnswer({
    required this.criteriaId,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.repeatedFaultCount = 0,
    this.isCcp = false,
    this.isRisk = false,
  });

  /// Serializes to JSON-compatible map for draft storage.
  Map<String, dynamic> toJson() => {
    'criteriaId': criteriaId,
    'value': value,
    'numericValue': numericValue,
    'note': note,
    'photoUrl': photoUrl,
    'repeatedFaultCount': repeatedFaultCount,
    'isCcp': isCcp,
    'isRisk': isRisk,
  };

  /// Restores from a JSON map (from draft storage).
  factory AuditAnswer.fromJson(Map<String, dynamic> json) => AuditAnswer(
    criteriaId: json['criteriaId'] as String,
    value: json['value'] as String?,
    numericValue: (json['numericValue'] as num?)?.toDouble(),
    note: json['note'] as String?,
    photoUrl: json['photoUrl'] as String?,
    repeatedFaultCount: (json['repeatedFaultCount'] as int?) ?? 0,
    isCcp: (json['isCcp'] as bool?) ?? false,
    isRisk: (json['isRisk'] as bool?) ?? false,
  );

  /// Converts to submission API payload.
  SubmissionAnswerInput toInput() => SubmissionAnswerInput(
    criteriaId: criteriaId,
    value: value,
    numericValue: numericValue,
    note: note,
    photoUrl: photoUrl,
    isRepeatedError: isRepeatedError,
    repeatedFaults: repeatedFaultCount,
    isCcp: isCcp,
    isRisk: isRisk,
  );
}
