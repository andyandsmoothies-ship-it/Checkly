import 'dart:convert';
import 'answer_dto.dart';

String? _parseJsonString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
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
  final double? rawEarnedPoints;
  final double? rawMaxPoints;
  final bool? isWeighted;
  final String? scoringMode;
  final String? areaManagerId;
  final String? areaManagerName;
  final String? storeManagerId;
  final String? storeManagerName;

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
    this.rawEarnedPoints,
    this.rawMaxPoints,
    this.isWeighted,
    this.scoringMode,
    this.areaManagerId,
    this.areaManagerName,
    this.storeManagerId,
    this.storeManagerName,
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
        rawEarnedPoints: (json['rawEarnedPoints'] as num?)?.toDouble(),
        rawMaxPoints: (json['rawMaxPoints'] as num?)?.toDouble(),
        isWeighted: json['isWeighted'] as bool?,
        scoringMode: json['scoringMode'] as String?,
        areaManagerId: json['areaManagerId'] as String?,
        areaManagerName: json['areaManagerName'] as String?,
        storeManagerId: json['storeManagerId'] as String?,
        storeManagerName: json['storeManagerName'] as String?,
      );
}
