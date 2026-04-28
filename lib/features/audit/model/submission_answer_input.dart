/// Answer payload within a submission.
class SubmissionAnswerInput {
  final String criteriaId;
  final String? value;
  final double? numericValue;
  final String? note;
  final String? photoUrl;
  final bool isRepeatedError;
  final int repeatedFaults;
  final bool isCcp;
  final bool isRisk;

  const SubmissionAnswerInput({
    required this.criteriaId,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.isRepeatedError = false,
    this.repeatedFaults = 0,
    this.isCcp = false,
    this.isRisk = false,
  });

  Map<String, dynamic> toJson() => {
    'criteriaId': criteriaId,
    'value': value,
    'numericValue': numericValue,
    'note': note,
    'photoUrl': photoUrl,
    'isRepeatedError': isRepeatedError,
    'repeatedFaults': repeatedFaults,
    'isCcp': isCcp,
    'isRisk': isRisk,
  };
}
