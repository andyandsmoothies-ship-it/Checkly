import 'dart:convert';

import 'package:dio/dio.dart';
import '../../features/action_plans/model/action_plan_dto.dart';
import '../../features/action_plans/models/add_comment_request.dart';
import '../../features/action_plans/models/comment_dto.dart';
import '../../features/action_plans/manager/action_plan_manager.dart';
import 'package:checkly/_shared/services/sync_interfaces.dart';
import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../database/dao/outbox_dao.dart';

// ============================================================
// Concrete adapter: SyncApi → wraps SubmissionApiService + Dio
// ============================================================

/// Production implementation of [SyncApi] for real network sync.
class SyncApiAdapter implements SyncApi {
  final Dio _dio;

  SyncApiAdapter(this._dio);

  /// Returns true if [url] is a local device file path that must not reach
  /// the backend database.
  bool _isLocalPath(String url) =>
      url.startsWith('/') || url.startsWith('file://');

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    // Decode the stored JSON string and strip local file paths from photoUrl
    // fields so they never pollute the backend Postgres database.
    final payload = Map<String, dynamic>.from(
      jsonDecode(submission.payload) as Map,
    );

    final answers = payload['answers'];
    if (answers is List) {
      for (final a in answers) {
        if (a is Map<String, dynamic>) {
          final url = a['photoUrl'];
          if (url is String && _isLocalPath(url)) {
            a['photoUrl'] = null;
          }
        }
      }
    }

    // Extract routing metadata — never send this field to the backend.
    final targetId = payload.remove('targetSubmissionId') as String?;

    if (targetId != null && targetId.isNotEmpty) {
      // Finalize an existing server-side DRAFT submission.
      // Backend: PUT /api/submissions/{id}/finalize (FinalizeSubmission.cs)
      await _dio.put(
        '/submissions/$targetId/finalize',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
    } else {
      // Fresh new audit — use idempotent POST.
      await _dio.post(
        '/submissions',
        data: payload,
        options: Options(
          headers: {'X-Idempotency-Key': submission.idempotencyKey},
          contentType: Headers.jsonContentType,
        ),
      );
    }
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async {
    // Delta pull — future enhancement to sync templates/stores/submissions.
    // For now, individual managers handle their own cache refresh.
    return DeltaPullResult(serverTimestamp: DateTime.now());
  }

  @override
  Future<List<dynamic>> pullGlobalRisks(DateTime? since) async {
    final allRisks = <dynamic>[];
    int page = 1;
    const pageSize = 100;
    const maxPages = 10; // Safety cap: 10 pages × 100 = 1000 risks max

    while (page <= maxPages) {
      final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
      if (since != null) {
        params['since'] = since.toIso8601String();
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/global-risks',
        queryParameters: params,
      );

      final list = response.data?['items'] as List<dynamic>? ?? [];
      allRisks.addAll(list);

      if (list.length < pageSize) break;
      page++;
    }

    return allRisks;
  }

  @override
  Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
    await _dio.post(
      '/submissions/${risk.submissionId}/risks',
      data: {'globalRiskId': risk.globalRiskId},
    );
  }
}

// ============================================================
// Concrete adapter: Outbox → wraps OutboxDao
// ============================================================

/// Production implementation of [Outbox] backed by Drift OutboxDao.
class OutboxAdapter implements Outbox {
  final OutboxDao _dao;

  OutboxAdapter(this._dao);

  @override
  List<PendingSubmission> get pending => []; // Loaded async on demand

  @override
  Future<void> add(PendingSubmission entry) async {
    // Entries are added directly via OutboxDao in AuditManager
  }

  @override
  Future<void> remove(String idempotencyKey) async {
    await _dao.removeByIdempotencyKey(idempotencyKey);
  }
}

// ============================================================
// Concrete adapter: AuthCheck → wraps AuthManager
// ============================================================

/// Production implementation of [AuthCheck] using AuthManager state.
class AuthCheckAdapter implements AuthCheck {
  final AuthManager _auth;

  AuthCheckAdapter(this._auth);

  @override
  bool get isLoggedIn => _auth.authState.value == AuthState.authenticated;
}

// ============================================================
// Concrete adapter: ActionPlanApi → wraps Dio
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
    // Normalize to absolute so Image.network() can render it without crashing.
    if (raw.startsWith('/')) {
      final base = _dio.options.baseUrl.endsWith('/')
          ? _dio.options.baseUrl.substring(0, _dio.options.baseUrl.length - 1)
          : _dio.options.baseUrl;
      return '$base$raw';
    }
    return raw;
  }

  @override
  Future<List<ActionPlanDto>> fetchActionPlans() async {
    // Auto-paginate — page size 100, max 5 pages = 500 items (matches local cache limit).
    // Backend returns PagedResult<ActionPlanDto>: { items: [...], total, page, pageSize }.
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

// ============================================================
// Concrete adapter: UserRoleProvider → wraps AuthManager
// ============================================================

/// Production implementation of [UserRoleProvider] using AuthManager.
class UserRoleAdapter implements UserRoleProvider {
  final AuthManager _auth;

  UserRoleAdapter(this._auth);

  @override
  String get role => _auth.currentUser?.role ?? 'unknown';
}
