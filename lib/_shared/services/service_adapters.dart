import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:checkly/features/action_plans/manager/action_plan_api.dart';
import 'package:checkly/_shared/services/pending_submission.dart';
import 'package:checkly/_shared/services/delta_pull_result.dart';
import 'package:checkly/_shared/services/pending_submission_risk.dart';
import 'package:checkly/_shared/services/sync_api.dart';
import 'package:checkly/_shared/services/outbox.dart';
import 'package:checkly/_shared/services/auth_check.dart';
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

  @override
  Future<List<dynamic>> pullProgramAssignments() async {
    // GET /api/programs/assignments/my — returns full list (no pagination needed
    // as each SM typically has <50 active assignments at a time).
    final response = await _dio.get<Map<String, dynamic>>(
      '/programs/assignments/my',
    );
    return response.data?['items'] as List<dynamic>? ?? [];
  }

  @override
  Future<void> pushProgramEvidence(
    String assignmentId,
    List<Map<String, dynamic>> evidenceItems,
  ) async {
    // POST /api/programs/assignments/{id}/submit
    await _dio.post(
      '/programs/assignments/$assignmentId/submit',
      data: {'evidenceItems': evidenceItems},
    );
  }

  @override
  Future<void> pushProgramPhoto(String photoLocalKey, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    await _dio.post(
      '/photos/programs/evidence/$photoLocalKey',
      data: formData,
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
// Concrete adapter: UserRoleProvider → wraps AuthManager
// ============================================================

/// Production implementation of [UserRoleProvider] using AuthManager.
class UserRoleAdapter implements UserRoleProvider {
  final AuthManager _auth;

  UserRoleAdapter(this._auth);

  @override
  String get role => _auth.currentUser?.role ?? 'unknown';
}
