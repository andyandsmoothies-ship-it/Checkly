import 'package:dio/dio.dart';

import '../../../_shared/utils/isolate_parser.dart';
import '../model/submission_dto.dart';
import '../model/survey_result_dto.dart';


import '../../../_shared/services/sync_interfaces.dart';

/// API service for submission endpoints.
class SubmissionApiService implements PhotoApi {
  final Dio _dio;

  SubmissionApiService(this._dio);

  /// POST /submissions — returns [SubmissionDto].
  Future<SubmissionDto> createSubmission(
    CreateSubmissionRequest request,
  ) async {
    final response = await _dio.post('/submissions', data: request.toJson());
    return SubmissionDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /submissions — returns list of [SubmissionDto] (paginated).
  Future<List<SubmissionDto>> getSubmissions({
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/submissions',
      queryParameters: {'page': page, 'pageSize': pageSize},
      options: Options(responseType: ResponseType.plain),
    );
    
    return IsolateParser.parseList<SubmissionDto>(
      json: response.data,
      parser: SubmissionDto.fromJson,
      listKey: 'items',
    );
  }

  /// GET /submissions/{id} — returns [SubmissionDetailDto].
  Future<SubmissionDetailDto> getSubmission(String id) async {
    final response = await _dio.get('/submissions/$id');
    return SubmissionDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// PUT /submissions/{id} — update submission (e.g. scheduled → draft).
  Future<SubmissionDto> updateSubmission(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('/submissions/$id', data: body);
    return SubmissionDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /submissions/{id}/void — admin-only. Neutralizes an audit.
  Future<void> voidSubmission(String id, String reason) async {
    await _dio.post('/submissions/$id/void', data: {'voidReason': reason});
  }

  /// PUT /submissions/{id}/finalize — atomic draft → completed.
  Future<SubmissionDto> finalizeSubmission(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('/submissions/$id/finalize', data: body);
    return SubmissionDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /photos/upload/{submissionId} — multipart upload.
  /// [answerId] — if provided, the server patches the Answer row with the CDN URL.
  @override
  Future<String> uploadPhoto(
    String submissionId,
    String filePath, {
    String? answerId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    // Route uses path segment /upload/{submissionId} — NOT query param.
    // Optional answerId appended as query param for server-side answer patching.
    final query = answerId != null ? '?answerId=$answerId' : '';
    final response = await _dio.post(
      '/photos/upload/$submissionId$query',
      data: formData,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  /// PUT /submissions/{id}/review — approve, reject, or flag an audit.
  Future<Map<String, dynamic>> reviewSubmission(
    String id, {
    required String status,
  }) async {
    final response = await _dio.put(
      '/submissions/$id/review',
      data: {'status': status},
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /submissions/survey-results?templateId=... — aggregated survey results.
  Future<List<SurveyQuestionResult>> getSurveyResults(String templateId) async {
    final response = await _dio.get(
      '/submissions/survey-results',
      queryParameters: {'templateId': templateId},
    );
    final data = response.data;
    final list = (data is List) ? data : (data['items'] as List<dynamic>);
    return list
        .map((j) => SurveyQuestionResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET /submissions?completedBefore=...&page=...&pageSize=...
  /// Returns archived submissions whose terminal event predates [before].
  /// Server applies caller's RBAC scope automatically.
  Future<List<SubmissionDto>> searchArchive({
    required DateTime before,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/submissions',
      queryParameters: {
        'completedBefore': before.toIso8601String(),
        'page': page,
        'pageSize': pageSize,
      },
      options: Options(responseType: ResponseType.plain),
    );
    
    return IsolateParser.parseList<SubmissionDto>(
      json: response.data,
      parser: SubmissionDto.fromJson,
      listKey: 'items',
    );
  }
}
