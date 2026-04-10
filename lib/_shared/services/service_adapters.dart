import 'dart:convert';

import 'package:dio/dio.dart';
import '../../features/action_plans/model/action_plan_dto.dart';
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
    final payload =
        Map<String, dynamic>.from(jsonDecode(submission.payload) as Map);

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

    await _dio.post(
      '/submissions',
      data: payload,
      options: Options(
        headers: {'X-Idempotency-Key': submission.idempotencyKey},
        contentType: Headers.jsonContentType,
      ),
    );
  }

  @override
  Future<DeltaPullResult> pullDeltas(DateTime? since) async {
    // Delta pull — future enhancement to sync templates/stores/submissions.
    // For now, individual managers handle their own cache refresh.
    return DeltaPullResult(serverTimestamp: DateTime.now());
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
    final response = await _dio.put('/action-plans/$id', data: fields);
    return ActionPlanDto.fromJson(response.data as Map<String, dynamic>);
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
