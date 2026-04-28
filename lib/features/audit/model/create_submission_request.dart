import 'submission_answer_input.dart';

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
  final bool hasGlobalRisk;

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
    this.hasGlobalRisk = false,
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
    'hasGlobalRisk': hasGlobalRisk,
  };
}
