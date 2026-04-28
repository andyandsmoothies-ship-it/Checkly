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
  final double? rawEarnedPoints;
  final double? rawMaxPoints;
  final bool? isWeighted;
  final String? scoringMode;

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
    this.rawEarnedPoints,
    this.rawMaxPoints,
    this.isWeighted,
    this.scoringMode,
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
    rawEarnedPoints: (json['rawEarnedPoints'] as num?)?.toDouble(),
    rawMaxPoints: (json['rawMaxPoints'] as num?)?.toDouble(),
    isWeighted: json['isWeighted'] as bool?,
    scoringMode: json['scoringMode'] as String?,
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
    rawEarnedPoints: rawEarnedPoints,
    rawMaxPoints: rawMaxPoints,
    isWeighted: isWeighted,
    scoringMode: scoringMode,
  );
}
