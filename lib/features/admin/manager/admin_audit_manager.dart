import 'package:flutter/foundation.dart';

import '../services/admin_api_service.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../stores/services/store_api_service.dart';
import '../../templates/services/template_api_service.dart';
import '../../auth/manager/auth_manager.dart';

/// Schedule form data returned by [AdminAuditManager.loadScheduleData].
class ScheduleFormData {
  final List<Map<String, dynamic>> templates;
  final List<Map<String, dynamic>> allStores;
  final List<Map<String, dynamic>> allAuditors;

  const ScheduleFormData({
    required this.templates,
    required this.allStores,
    required this.allAuditors,
  });
}

/// PFA Manager for Admin Audit Workflow pages.
///
/// Wraps the READ operations for:
/// - [ScheduleAuditForm]: templates + stores + user list (parallel fetch)
/// - [AuditApprovalPage]: completed submissions list
///
/// Mutations (createSubmission, reviewSubmission) stay in their pages
/// because they require dialog-coupled UX and scoped snackbar feedback.
class AdminAuditManager extends ChangeNotifier {
  final AdminApiService _adminApi;
  final StoreApiService _storeApi;
  final TemplateApiService _templateApi;
  final SubmissionApiService _submissionApi;
  final AuthManager _auth;

  AdminAuditManager({
    required AdminApiService adminApi,
    required StoreApiService storeApi,
    required TemplateApiService templateApi,
    required SubmissionApiService submissionApi,
    required AuthManager auth,
  }) : _adminApi = adminApi,
       _storeApi = storeApi,
       _templateApi = templateApi,
       _submissionApi = submissionApi,
       _auth = auth;

  // ---------- Schedule Form State ----------
  bool isScheduleLoading = false;
  String? scheduleError;
  ScheduleFormData? scheduleData;

  // ---------- Approvals State ----------
  bool isApprovalsLoading = false;
  String? approvalsError;
  List<SubmissionDto> submissions = [];

  // ---------- Schedule Form Load ----------

  /// Fetches templates, stores, and users needed by [ScheduleAuditForm].
  /// Applies role-based filtering for area_manager users.
  Future<void> loadScheduleData() async {
    isScheduleLoading = true;
    scheduleError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _templateApi.getTemplates(),
        _storeApi.getStores(),
        _adminApi.getUsers(),
      ]);

      final templates = results[0] as List<dynamic>;
      final stores = results[1] as List<dynamic>;
      final users = results[2] as List<Map<String, dynamic>>;

      // Determine current user's role and area for filtering
      final currentUserId = _auth.currentUser?.userId;
      final currentUserRole = _auth.currentUser?.role ?? 'auditor';
      Map<String, dynamic>? currentUserRecord;
      if (currentUserId != null) {
        currentUserRecord = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['id'] == currentUserId,
          orElse: () => null,
        );
      }
      final myAreaId = currentUserRecord?['areaId'] as String?;

      // Build template list
      final templateList = templates
          .map(
            (t) => <String, dynamic>{
              'id': (t is Map) ? t['id'] : t.id,
              'title': (t is Map) ? t['title'] : t.title,
            },
          )
          .toList();

      // Build store list (with areaId for cross-filtering)
      var storeList = stores
          .map(
            (s) => <String, dynamic>{
              'id': (s is Map) ? s['id'] : s.id,
              'name': (s is Map) ? s['name'] : s.name,
              'areaId': (s is Map) ? s['areaId'] : null,
            },
          )
          .toList();

      // Base auditor filter: active auditors and admins only
      var auditorList = users
          .where(
            (u) =>
                (u['role'] == 'auditor' || u['role'] == 'admin') &&
                u['isLocked'] != true,
          )
          .toList();

      // Role-based filtering for area_manager
      if (currentUserRole == 'area_manager' && myAreaId != null) {
        storeList = storeList.where((s) => s['areaId'] == myAreaId).toList();
        auditorList = auditorList
            .where((u) => u['areaId'] == myAreaId || u['areaId'] == null)
            .toList();
      } else if (currentUserRole == 'area_manager' && myAreaId == null) {
        // Safety: AM with no area sees nothing
        storeList = [];
        auditorList = [];
      }

      scheduleData = ScheduleFormData(
        templates: templateList,
        allStores: storeList,
        allAuditors: auditorList,
      );
    } catch (e) {
      scheduleError = e.toString();
    } finally {
      isScheduleLoading = false;
      notifyListeners();
    }
  }

  // ---------- Approvals Load ----------

  /// Fetches completed submissions for [AuditApprovalPage].
  Future<void> loadApprovals() async {
    isApprovalsLoading = true;
    approvalsError = null;
    notifyListeners();

    try {
      final subs = await _submissionApi.getSubmissions(pageSize: 100);
      submissions = subs.where((s) => s.status == 'completed').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      approvalsError = e.toString();
    } finally {
      isApprovalsLoading = false;
      notifyListeners();
    }
  }
}
