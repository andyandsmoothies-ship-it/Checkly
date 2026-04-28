/// Single answer DTO.
class AnswerDto {
  final String id;
  final String? criteriaId;
  final String? criteriaLabel;
  final String? value;
  final double? numericValue;
  final String? note;
  final String? photoUrl;
  final bool isRepeatedError;
  final bool isCcp;
  final bool isRisk;
  final String? actionPlanId;

  const AnswerDto({
    required this.id,
    this.criteriaId,
    this.criteriaLabel,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.isRepeatedError = false,
    this.isCcp = false,
    this.isRisk = false,
    this.actionPlanId,
  });

  factory AnswerDto.fromJson(Map<String, dynamic> json) => AnswerDto(
    id: json['id'] as String,
    criteriaId: json['criteriaId'] as String?,
    criteriaLabel: json['criteriaLabel'] as String?,
    value: json['value'] as String?,
    numericValue: (json['numericValue'] as num?)?.toDouble(),
    note: json['note'] as String?,
    photoUrl: json['photoUrl'] as String?,
    isRepeatedError: json['isRepeatedError'] as bool? ?? false,
    isCcp: json['isCcp'] as bool? ?? false,
    isRisk: json['isRisk'] as bool? ?? false,
    actionPlanId: json['actionPlanId'] as String?,
  );
}
