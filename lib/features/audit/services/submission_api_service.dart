import 'package:dio/dio.dart';

import '../model/submission_dto.dart';

/// API service for submission endpoints.
class SubmissionApiService {
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
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((j) => SubmissionDto.fromJson(j as Map<String, dynamic>))
        .toList();
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

  /// PUT /submissions/{id}/finalize — atomic draft → completed.
  Future<SubmissionDto> finalizeSubmission(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put('/submissions/$id/finalize', data: body);
    return SubmissionDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /photos/upload — multipart upload
  Future<String> uploadPhoto(String submissionId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/photos/upload?submissionId=$submissionId',
      data: formData,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
