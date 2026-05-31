import 'package:dio/dio.dart';

import '../../../_shared/utils/isolate_parser.dart';
import '../models/template_dto.dart';

/// API service for template endpoints.
class TemplateApiService {
  final Dio _dio;

  TemplateApiService(this._dio);

  /// GET /templates — returns list of [TemplateDto].
  Future<List<TemplateDto>> getTemplates() async {
    final response = await _dio.get(
      '/templates',
      options: Options(responseType: ResponseType.plain),
    );
    return IsolateParser.parseList<TemplateDto>(
      json: response.data,
      parser: TemplateDto.fromJson,
      listKey: 'items',
    );
  }

  /// GET /templates/{id} → TemplateTreeDto (nested tree)
  Future<TemplateTreeDto> getTemplateTree(String id) async {
    final response = await _dio.get('/templates/$id');
    return TemplateTreeDto.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Template Mutations ──────────────────────────────────────

  /// POST /templates — create a new template.
  Future<Map<String, dynamic>> createTemplate({
    required String title,
    required String type,
    String? description,
    String? scoringLogicConfig,
  }) async {
    final body = <String, dynamic>{'title': title, 'type': type};
    if (description != null) body['description'] = description;
    if (scoringLogicConfig != null) {
      body['scoringLogicConfig'] = scoringLogicConfig;
    }
    final response = await _dio.post('/templates', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /templates/{id} — update template metadata.
  Future<Map<String, dynamic>> updateTemplate(
    String id, {
    String? title,
    String? description,
    String? type,
    String? scoringLogicConfig,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (type != null) body['type'] = type;
    if (scoringLogicConfig != null) {
      body['scoringLogicConfig'] = scoringLogicConfig;
    }

    final response = await _dio.put('/templates/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /templates/{id} — soft-delete.
  Future<void> deleteTemplate(String id) async {
    await _dio.delete('/templates/$id');
  }

  /// POST /templates/{id}/clone — duplicate template tree as a draft.
  Future<TemplateDto> cloneTemplate(String id) async {
    final response = await _dio.post('/templates/$id/clone');
    return TemplateDto.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Batch Tree Save ──────────────────────────────────────────

  /// PUT /templates/{id}/tree — atomic upsert of full template tree.
  /// Returns the updated TemplateTreeDto.
  /// Throws DioException with 409 status for version conflicts.
  Future<TemplateTreeDto> saveTemplateTree(
    String id, {
    required String title,
    required String type,
    String? description,
    String? scoringLogicConfig,
    String? displayNoun,
    required int version,
    required List<Map<String, dynamic>> groups,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'type': type,
      'version': version,
      'groups': groups,
    };
    if (description != null) body['description'] = description;
    if (scoringLogicConfig != null) {
      body['scoringLogicConfig'] = scoringLogicConfig;
    }
    if (displayNoun != null) body['displayNoun'] = displayNoun;

    final response = await _dio.put('/templates/$id/tree', data: body);
    return TemplateTreeDto.fromJson(response.data as Map<String, dynamic>);
  }
}
