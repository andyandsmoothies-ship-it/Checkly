import 'package:flutter/foundation.dart';

import '../services/admin_api_service.dart';
import '../../audit/model/submission_dto.dart';
import '../../audit/services/submission_api_service.dart';
import '../../stores/services/store_api_service.dart';
import '../../templates/services/template_api_service.dart';
import '../../auth/manager/auth_manager.dart';
import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/constants/user_persona.dart';

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

  /// True when the approvals fetch returned exactly 100 rows — the hard cap.
  /// The UI should show a visible warning banner when this is true.
  bool hasApprovalsTruncationWarning = false;
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
        _adminApi.searchUsersByCapability(
          AppCapabilities.submissionsCreate,
        ), // Backend PBAC filter
      ]);

      final templates = results[0] as List<dynamic>;
      final stores = results[1] as List<dynamic>;
      final users = results[2] as List<Map<String, dynamic>>;

      // Determine current user's role and assigned stores for filtering
      final currentUserId = _auth.currentUser?.userId;
      final currentUserRole = _auth.currentUser?.role ?? 'auditor';
      Map<String, dynamic>? currentUserRecord;
      if (currentUserId != null) {
        currentUserRecord = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['id'] == currentUserId,
          orElse: () => null,
        );
      }
      final assignedStoreIds =
          (currentUserRecord?['assignedStoreIds'] as List<dynamic>?)
              ?.cast<String>() ??
          <String>[];

      // Build template list
      final templateList = templates
          .map(
            (t) => <String, dynamic>{
              'id': (t is Map) ? t['id'] : t.id,
              'title': (t is Map) ? t['title'] : t.title,
            },
          )
          .toList();

      // Build store list
      var storeList = stores
          .map(
            (s) => <String, dynamic>{
              'id': (s is Map) ? s['id'] : s.id,
              'name': (s is Map) ? s['name'] : s.name,
            },
          )
          .toList();

      // Build auditor list: users filtered by submissions:create capability (PBAC backend filter)
      var auditorList = users;

      // Role-based filtering for area_manager
      if (UserPersona.fromRole(currentUserRole) == UserPersona.areaManager) {
        storeList = storeList
            .where((s) => assignedStoreIds.contains(s['id']))
            .toList();
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
  ///
  /// Note: capped at 100 rows per server page. When exactly 100 rows are
  /// returned, [hasApprovalsTruncationWarning] is set so the UI can show a
  /// visible notice to the admin.
  Future<void> loadApprovals() async {
    isApprovalsLoading = true;
    approvalsError = null;
    notifyListeners();

    try {
      final subs = await _submissionApi.getSubmissions(pageSize: 100);
      hasApprovalsTruncationWarning = subs.length >= 100;
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
