import 'package:dio/dio.dart';

import '../model/template_dto.dart';

/// API service for template endpoints.
class TemplateApiService {
  final Dio _dio;

  TemplateApiService(this._dio);

  /// GET /templates — returns list of [TemplateDto].
  Future<List<TemplateDto>> getTemplates() async {
    final response = await _dio.get('/templates');
    final list = response.data as List<dynamic>;
    return list
        .map((j) => TemplateDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET /templates/{id} → TemplateTreeDto (nested tree)
  Future<TemplateTreeDto> getTemplateTree(String id) async {
    final response = await _dio.get('/templates/$id');
    return TemplateTreeDto.fromJson(response.data as Map<String, dynamic>);
  }
}
