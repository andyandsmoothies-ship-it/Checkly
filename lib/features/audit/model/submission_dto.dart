// Dart models matching backend Submission DTOs.
// See: server/Features/Submissions/Dtos.cs

/// Request to create a submission — sent to POST /submissions.
class CreateSubmissionRequest {
  final String templateId;
  final String storeId;
  final double clientScore;
  final String? sectionScores;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final List<SubmissionAnswerInput> answers;
  final String? idempotencyKey;

  const CreateSubmissionRequest({
    required this.templateId,
    required this.storeId,
    required this.clientScore,
    this.sectionScores,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    required this.answers,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'storeId': storeId,
    'clientScore': clientScore,
    'sectionScores': sectionScores,
    'notes': notes,
    'gpsLat': gpsLat,
    'gpsLng': gpsLng,
    'answers': answers.map((a) => a.toJson()).toList(),
    'idempotencyKey': idempotencyKey,
  };
}

/// Answer payload within a submission.
class SubmissionAnswerInput {
  final String criteriaId;
  final String? value;
  final double? numericValue;
  final String? note;
  final String? photoUrl;
  final bool isRepeatedError;

  const SubmissionAnswerInput({
    required this.criteriaId,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.isRepeatedError = false,
  });

  Map<String, dynamic> toJson() => {
    'criteriaId': criteriaId,
    'value': value,
    'numericValue': numericValue,
    'note': note,
    'photoUrl': photoUrl,
    'isRepeatedError': isRepeatedError,
  };
}

/// DTO returned from POST /submissions and GET /submissions.
class SubmissionDto {
  final String id;
  final String? templateId;
  final String? templateTitle;
  final String? storeId;
  final String? storeName;
  final String? auditorId;
  final String? auditorName;
  final String status;
  final double? totalScore;
  final String? sectionScores;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const SubmissionDto({
    required this.id,
    this.templateId,
    this.templateTitle,
    this.storeId,
    this.storeName,
    this.auditorId,
    this.auditorName,
    required this.status,
    this.totalScore,
    this.sectionScores,
    this.notes,
    required this.createdAt,
    this.completedAt,
  });

  factory SubmissionDto.fromJson(Map<String, dynamic> json) => SubmissionDto(
    id: json['id'] as String,
    templateId: json['templateId'] as String?,
    templateTitle: json['templateTitle'] as String?,
    storeId: json['storeId'] as String?,
    storeName: json['storeName'] as String?,
    auditorId: json['auditorId'] as String?,
    auditorName: json['auditorName'] as String?,
    status: json['status'] as String,
    totalScore: (json['totalScore'] as num?)?.toDouble(),
    sectionScores: json['sectionScores'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}

/// Detailed submission with answers — GET /submissions/{id}.
class SubmissionDetailDto {
  final String id;
  final String? templateTitle;
  final String? storeName;
  final String? auditorName;
  final String status;
  final double? totalScore;
  final String? sectionScores;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<AnswerDto> answers;

  const SubmissionDetailDto({
    required this.id,
    this.templateTitle,
    this.storeName,
    this.auditorName,
    required this.status,
    this.totalScore,
    this.sectionScores,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    required this.createdAt,
    this.completedAt,
    required this.answers,
  });

  factory SubmissionDetailDto.fromJson(Map<String, dynamic> json) =>
      SubmissionDetailDto(
        id: json['id'] as String,
        templateTitle: json['templateTitle'] as String?,
        storeName: json['storeName'] as String?,
        auditorName: json['auditorName'] as String?,
        status: json['status'] as String,
        totalScore: (json['totalScore'] as num?)?.toDouble(),
        sectionScores: json['sectionScores'] as String?,
        notes: json['notes'] as String?,
        gpsLat: (json['gpsLat'] as num?)?.toDouble(),
        gpsLng: (json['gpsLng'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        answers: (json['answers'] as List<dynamic>)
            .map((a) => AnswerDto.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

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

  const AnswerDto({
    required this.id,
    this.criteriaId,
    this.criteriaLabel,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.isRepeatedError = false,
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
  );
}
