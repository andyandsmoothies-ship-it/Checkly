import 'package:dio/dio.dart';

import 'package:checkly/features/action_plans/manager/action_plan_api.dart';
import 'package:checkly/features/action_plans/model/action_plan_dto.dart';
import 'package:checkly/features/action_plans/models/add_comment_request.dart';
import 'package:checkly/features/action_plans/models/comment_dto.dart';

// ============================================================
// Concrete adapter: ActionPlanApi → wraps Dio
// Extracted from _shared/services/service_adapters.dart
// ============================================================

/// Production implementation of [ActionPlanApi] using Dio.
class ActionPlanApiAdapter implements ActionPlanApi {
  final Dio _dio;

  ActionPlanApiAdapter(this._dio);

  @override
  Future<ActionPlanDto> updateActionPlan(
    String id,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _dio.put('/action-plans/$id', data: fields);
      return ActionPlanDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> &&
            data['extensions']?['code'] == 'action_plan_already_closed') {
          throw const ActionPlanAlreadyClosedException();
        }
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadPhoto(String submissionId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/photos/upload/$submissionId',
      data: formData,
    );
    final raw = (response.data as Map<String, dynamic>)['url'] as String;
    // Server returns a relative URL (e.g. /api/photos/{id}/{file}).
    // Return raw so AppNetworkImage handles absolute conversion safely at runtime without hardcoding base URLs in the database.
    return raw;
  }

  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async {
    // Auto-paginate — page size 100, max 5 pages = 500 items (matches local cache limit).
    // Backend returns PagedResult<ActionPlanDto>: { items: [...], total, page, pageSize }
    final allPlans = <ActionPlanDto>[];
    int page = 1;
    const pageSize = 100;

    while (true) {
      final response = await _dio.get<Map<String, dynamic>>(
        '/action-plans',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final body = response.data!;
      final items = (body['items'] as List)
          .map((e) => ActionPlanDto.fromJson(e as Map<String, dynamic>))
          .toList();

      allPlans.addAll(items);

      final total = (body['total'] as num).toInt();
      if (allPlans.length >= total || items.isEmpty || page >= 5) break;
      page++;
    }

    return allPlans;
  }

  @override
  Future<CommentDto> addComment(
    String actionPlanId,
    AddCommentRequest request,
  ) async {
    final response = await _dio.post(
      '/action-plans/$actionPlanId/comments',
      data: request.toJson(),
    );
    return CommentDto.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ActionPlanDto?> fetchActionPlan(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/action-plans/$id',
      );
      return ActionPlanDto.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
