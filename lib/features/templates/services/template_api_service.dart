import 'package:dio/dio.dart';

import '../models/template_dto.dart';

/// API service for template endpoints.
class TemplateApiService {
  final Dio _dio;

  TemplateApiService(this._dio);

  /// GET /templates — returns list of [TemplateDto].
  Future<List<TemplateDto>> getTemplates() async {
    final response = await _dio.get('/templates');
    final data = response.data as Map<String, dynamic>;
    final list = data['items'] as List<dynamic>;
    return list
        .map((j) => TemplateDto.fromJson(j as Map<String, dynamic>))
        .toList();
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

  // ── Group CRUD ──────────────────────────────────────────────

  /// POST /templates/{templateId}/groups — create group.
  Future<Map<String, dynamic>> createGroup(
    String templateId, {
    required String title,
    String? description,
    double? weight,
    double? maxDeductionPoints,
    double? minusPerFault,
    int? orderIndex,
    String? parentId,
    String? metadata,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description != null) body['description'] = description;
    if (weight != null) body['weight'] = weight;
    if (maxDeductionPoints != null) {
      body['maxDeductionPoints'] = maxDeductionPoints;
    }
    if (minusPerFault != null) body['minusPerFault'] = minusPerFault;
    if (orderIndex != null) body['orderIndex'] = orderIndex;
    if (parentId != null) body['parentId'] = parentId;
    if (metadata != null) body['metadata'] = metadata;

    final response = await _dio.post(
      '/templates/$templateId/groups',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /templates/{templateId}/groups/{groupId} — update group.
  Future<Map<String, dynamic>> updateGroup(
    String templateId,
    String groupId, {
    String? title,
    String? description,
    double? weight,
    double? maxDeductionPoints,
    double? minusPerFault,
    int? orderIndex,
    String? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (weight != null) body['weight'] = weight;
    if (maxDeductionPoints != null) {
      body['maxDeductionPoints'] = maxDeductionPoints;
    }
    if (minusPerFault != null) body['minusPerFault'] = minusPerFault;
    if (orderIndex != null) body['orderIndex'] = orderIndex;
    if (metadata != null) body['metadata'] = metadata;

    final response = await _dio.put(
      '/templates/$templateId/groups/$groupId',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /templates/{templateId}/groups/{groupId} — soft-delete.
  Future<void> deleteGroup(String templateId, String groupId) async {
    await _dio.delete('/templates/$templateId/groups/$groupId');
  }

  // ── Criterion CRUD ──────────────────────────────────────────

  /// POST /templates/{tId}/groups/{gId}/criteria — create criterion.
  Future<Map<String, dynamic>> createCriterion(
    String templateId,
    String groupId, {
    required String label,
    required String inputType,
    String? description,
    double? pointsWeight,
    bool? isCcp,
    bool? isRisk,
    double? minusImpact,
    int? orderIndex,
    String? metadata,
  }) async {
    final body = <String, dynamic>{'label': label, 'inputType': inputType};
    if (description != null) body['description'] = description;
    if (pointsWeight != null) body['pointsWeight'] = pointsWeight;
    if (isCcp != null) body['isCcp'] = isCcp;
    if (isRisk != null) body['isRisk'] = isRisk;
    if (minusImpact != null) body['minusImpact'] = minusImpact;
    if (orderIndex != null) body['orderIndex'] = orderIndex;
    if (metadata != null) body['metadata'] = metadata;

    final response = await _dio.post(
      '/templates/$templateId/groups/$groupId/criteria',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /templates/{tId}/criteria/{cId} — update criterion.
  Future<Map<String, dynamic>> updateCriterion(
    String templateId,
    String criterionId, {
    String? label,
    String? inputType,
    String? description,
    double? pointsWeight,
    bool? isCcp,
    bool? isRisk,
    double? minusImpact,
    int? orderIndex,
    String? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (inputType != null) body['inputType'] = inputType;
    if (description != null) body['description'] = description;
    if (pointsWeight != null) body['pointsWeight'] = pointsWeight;
    if (isCcp != null) body['isCcp'] = isCcp;
    if (isRisk != null) body['isRisk'] = isRisk;
    if (minusImpact != null) body['minusImpact'] = minusImpact;
    if (orderIndex != null) body['orderIndex'] = orderIndex;
    if (metadata != null) body['metadata'] = metadata;

    final response = await _dio.put(
      '/templates/$templateId/criteria/$criterionId',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /templates/{tId}/criteria/{cId} — soft-delete.
  Future<void> deleteCriterion(String templateId, String criterionId) async {
    await _dio.delete('/templates/$templateId/criteria/$criterionId');
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
