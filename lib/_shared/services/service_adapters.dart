import 'package:dio/dio.dart';
import '../../features/action_plans/model/action_plan_dto.dart';
import '../../features/action_plans/manager/action_plan_manager.dart';
import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../database/dao/outbox_dao.dart';
import 'sync_engine.dart';

// ============================================================
// Concrete adapter: SyncApi → wraps SubmissionApiService + Dio
// ============================================================

/// Production implementation of [SyncApi] for real network sync.
class SyncApiAdapter implements SyncApi {
  final Dio _dio;

  SyncApiAdapter(this._dio);

  @override
  Future<void> pushSubmission(PendingSubmission submission) async {
    // The SyncEngine provides the raw payload (JSON string) from the outbox.
    // We POST it directly with the idempotency key header.
    await _dio.post(
      '/submissions',
      data: submission.payload,
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
