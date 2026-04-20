// Dart models matching backend Submission DTOs.
// See: server/Features/Submissions/Dtos.cs

import 'dart:convert';

String? _parseJsonString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

/// Request to create a submission — sent to POST /submissions.
class CreateSubmissionRequest {
  final String templateId;
  final String storeId;
  final double? clientScore;
  final String? sectionScores;
  final String? notes;
  final double? gpsLat;
  final double? gpsLng;
  final List<SubmissionAnswerInput>? answers;
  final String? idempotencyKey;
  final String? status;
  final DateTime? scheduledAt;
  final String? assignToAuditorId;

  const CreateSubmissionRequest({
    required this.templateId,
    required this.storeId,
    this.clientScore,
    this.sectionScores,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    this.answers,
    this.idempotencyKey,
    this.status,
    this.scheduledAt,
    this.assignToAuditorId,
  });

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'storeId': storeId,
    if (clientScore != null) 'clientScore': clientScore,
    'sectionScores': sectionScores,
    'notes': notes,
    'gpsLat': gpsLat,
    'gpsLng': gpsLng,
    if (answers != null) 'answers': answers!.map((a) => a.toJson()).toList(),
    'idempotencyKey': idempotencyKey,
    if (status != null) 'status': status,
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    if (assignToAuditorId != null) 'assignToAuditorId': assignToAuditorId,
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

/// DTO returned from POST /submissions and GET /submissions.
class SubmissionDto {
  final String id;
  final String? templateId;
  final String? templateTitle;
  final String? templateType;
  final String? displayNoun;
  final String? storeId;
  final String? storeName;
  final String? auditorId;
  final String? auditorName;
  final String status;
  final double? totalScore;
  final String? sectionScores;
  final String? notes;
  final String? reviewStatus;
  final String? approvedBy;
  final String? approverName;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? scheduledAt;
  final String? templateSnapshot;
  final int? templateVersion;
  final String? voidReason;
  final DateTime? voidedAt;

  const SubmissionDto({
    required this.id,
    this.templateId,
    this.templateTitle,
    this.templateType,
    this.displayNoun,
    this.storeId,
    this.storeName,
    this.auditorId,
    this.auditorName,
    required this.status,
    this.totalScore,
    this.sectionScores,
    this.notes,
    this.reviewStatus,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    required this.createdAt,
    this.completedAt,
    this.scheduledAt,
    this.templateSnapshot,
    this.templateVersion,
    this.voidReason,
    this.voidedAt,
  });

  /// Whether this audit has been voided.
  bool get isVoided => status == 'voided';

  /// Whether this audit is overdue (scheduled but past its date).
  bool get isOverdue {
    if (status != 'scheduled' || scheduledAt == null) return false;
    final localScheduled = scheduledAt!.toLocal();
    final scheduledDay = DateTime(
      localScheduled.year,
      localScheduled.month,
      localScheduled.day,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return scheduledDay.isBefore(today);
  }

  factory SubmissionDto.fromJson(Map<String, dynamic> json) => SubmissionDto(
    id: json['id'] as String,
    templateId: json['templateId'] as String?,
    templateTitle: json['templateTitle'] as String?,
    templateType: json['templateType'] as String?,
    displayNoun: json['displayNoun'] as String?,
    storeId: json['storeId'] as String?,
    storeName: json['storeName'] as String?,
    auditorId: json['auditorId'] as String?,
    auditorName: json['auditorName'] as String?,
    status: json['status'] as String,
    totalScore: (json['totalScore'] as num?)?.toDouble(),
    sectionScores: _parseJsonString(json['sectionScores']),
    notes: json['notes'] as String?,
    reviewStatus: json['reviewStatus'] as String?,
    approvedBy: json['approvedBy'] as String?,
    approverName: json['approverName'] as String?,
    approvedAt: json['approvedAt'] != null
        ? DateTime.parse(json['approvedAt'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    scheduledAt: json['scheduledAt'] != null
        ? DateTime.parse(json['scheduledAt'] as String)
        : null,
    templateSnapshot: _parseJsonString(json['templateSnapshot']),
    templateVersion: json['templateVersion'] as int?,
    voidReason: json['voidReason'] as String?,
    voidedAt: json['voidedAt'] != null
        ? DateTime.parse(json['voidedAt'] as String)
        : null,
  );

  /// Returns a copy of this DTO with [status] overridden.
  /// Used by [HistoryManager] to hydrate local draft state into the remote list.
  SubmissionDto withStatus(String newStatus) => SubmissionDto(
    id: id,
    templateId: templateId,
    templateTitle: templateTitle,
    templateType: templateType,
    displayNoun: displayNoun,
    storeId: storeId,
    storeName: storeName,
    auditorId: auditorId,
    auditorName: auditorName,
    status: newStatus,
    totalScore: totalScore,
    sectionScores: sectionScores,
    notes: notes,
    reviewStatus: reviewStatus,
    approvedBy: approvedBy,
    approverName: approverName,
    approvedAt: approvedAt,
    createdAt: createdAt,
    completedAt: completedAt,
    scheduledAt: scheduledAt,
    templateSnapshot: templateSnapshot,
    templateVersion: templateVersion,
    voidReason: voidReason,
    voidedAt: voidedAt,
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
  final String? templateSnapshot;
  final int? templateVersion;
  final String? voidReason;
  final DateTime? voidedAt;

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
    this.templateSnapshot,
    this.templateVersion,
    this.voidReason,
    this.voidedAt,
  });

  factory SubmissionDetailDto.fromJson(Map<String, dynamic> json) =>
      SubmissionDetailDto(
        id: json['id'] as String,
        templateTitle: json['templateTitle'] as String?,
        storeName: json['storeName'] as String?,
        auditorName: json['auditorName'] as String?,
        status: json['status'] as String,
        totalScore: (json['totalScore'] as num?)?.toDouble(),
        sectionScores: _parseJsonString(json['sectionScores']),
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
        templateSnapshot: _parseJsonString(json['templateSnapshot']),
        templateVersion: json['templateVersion'] as int?,
        voidReason: json['voidReason'] as String?,
        voidedAt: json['voidedAt'] != null
            ? DateTime.parse(json['voidedAt'] as String)
            : null,
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
