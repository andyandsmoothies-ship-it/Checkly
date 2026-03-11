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

  /// GET /submissions — returns list of [SubmissionDto].
  Future<List<SubmissionDto>> getSubmissions() async {
    final response = await _dio.get('/submissions');
    final list = response.data as List<dynamic>;
    return list
        .map((j) => SubmissionDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET /submissions/{id} — returns [SubmissionDetailDto].
  Future<SubmissionDetailDto> getSubmission(String id) async {
    final response = await _dio.get('/submissions/$id');
    return SubmissionDetailDto.fromJson(response.data as Map<String, dynamic>);
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
