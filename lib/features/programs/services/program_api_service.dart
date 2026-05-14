import 'package:dio/dio.dart';

/// DTO for a single evidence item returned in HQ assignment details.
class ProgramEvidenceDto {
  final String criteriaId;
  final String criteriaLabel;
  final String value;
  final String? photoUrl;
  final DateTime createdAt;

  const ProgramEvidenceDto({
    required this.criteriaId,
    required this.criteriaLabel,
    required this.value,
    this.photoUrl,
    required this.createdAt,
  });

  factory ProgramEvidenceDto.fromJson(Map<String, dynamic> json) =>
      ProgramEvidenceDto(
        criteriaId: json['criteriaId'] as String,
        criteriaLabel: json['criteriaLabel'] as String,
        value: json['value'] as String,
        photoUrl: json['photoUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// DTO for a full assignment detail as seen by HQ.
class ProgramAssignmentDetailDto {
  final String id;
  final String programId;
  final String storeId;
  final String storeName;
  final String status;
  final DateTime deadline;
  final DateTime createdAt;
  final List<ProgramEvidenceDto> evidence;

  const ProgramAssignmentDetailDto({
    required this.id,
    required this.programId,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.deadline,
    required this.createdAt,
    this.evidence = const [],
  });

  factory ProgramAssignmentDetailDto.fromJson(Map<String, dynamic> json) =>
      ProgramAssignmentDetailDto(
        id: json['id'] as String,
        programId: json['programId'] as String,
        storeId: json['storeId'] as String,
        storeName: json['storeName'] as String,
        status: json['status'] as String,
        deadline: DateTime.parse(json['deadline'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        evidence: json['evidence'] != null
            ? (json['evidence'] as List<dynamic>)
                  .map(
                    (e) =>
                        ProgramEvidenceDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : const [],
      );
}

/// Paginated response envelope for GET /api/programs/{id}/assignments.
class AssignmentDetailPagedResponse {
  final List<ProgramAssignmentDetailDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const AssignmentDetailPagedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory AssignmentDetailPagedResponse.fromJson(Map<String, dynamic> json) =>
      AssignmentDetailPagedResponse(
        items: (json['items'] as List<dynamic>)
            .map(
              (e) => ProgramAssignmentDetailDto.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
        totalCount: json['totalCount'] as int,
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
      );
}

/// DTO for the aggregated summary of a Program's assignments.
class ProgramSummaryResponse {
  final int total;
  final int pending;
  final int overdue;
  final int submitted;
  final int needsRevision;
  final int verified;
  final int completionRate;

  const ProgramSummaryResponse({
    required this.total,
    required this.pending,
    required this.overdue,
    required this.submitted,
    required this.needsRevision,
    required this.verified,
    required this.completionRate,
  });

  factory ProgramSummaryResponse.fromJson(Map<String, dynamic> json) =>
      ProgramSummaryResponse(
        total: json['total'] as int,
        pending: json['pending'] as int,
        overdue: json['overdue'] as int,
        submitted: json['submitted'] as int,
        needsRevision: json['needsRevision'] as int,
        verified: json['verified'] as int,
        completionRate: json['completionRate'] as int,
      );
}

/// Service wrapping Dio to interact with the Programs backend API.
///
/// Designed for HQ (admin) use: online-only, no offline caching.
/// Error handling: callers receive [DioException] on network/server errors.
class ProgramApiService {
  final Dio _dio;

  ProgramApiService(this._dio);

  /// Returns a paginated list of programs.
  /// GET /api/programs?page={page}
  Future<Map<String, dynamic>> getPrograms({int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/programs',
      queryParameters: {'page': page},
    );
    return response.data!;
  }

  /// Returns paginated assignment details for a specific program.
  /// GET /api/programs/{programId}/assignments?status={status}&page={page}
  Future<AssignmentDetailPagedResponse> getProgramAssignments(
    String programId, {
    String? status,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/programs/$programId/assignments',
      queryParameters: queryParams,
    );
    return AssignmentDetailPagedResponse.fromJson(response.data!);
  }

  /// Returns the aggregated summary of assignments for a specific program.
  /// GET /api/programs/{programId}/summary
  Future<ProgramSummaryResponse> getProgramSummary(String programId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/programs/$programId/summary',
    );
    return ProgramSummaryResponse.fromJson(response.data!);
  }

  /// Creates a new program and issues it to the specified stores.
  /// POST /api/programs → 201 Created with { programId, assignmentCount }
  ///
  /// Throws [DioException] on network or non-2xx server errors.
  Future<Map<String, dynamic>> createProgram({
    required String title,
    required String category,
    required DateTime deadline,
    required String templateId,
    required List<String> storeIds,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/programs',
      data: {
        'title': title,
        'category': category,
        'deadline': deadline.toIso8601String(),
        'templateId': templateId,
        'storeIds': storeIds,
      },
    );
    return response.data!;
  }
}
