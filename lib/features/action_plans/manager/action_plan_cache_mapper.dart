import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../_shared/database/app_database.dart';
import '../model/action_plan_dto.dart';

/// Helper to map between [ActionPlanDto] and [CachedActionPlans] Drift rows,
/// extracted to keep ActionPlanManager below the size threshold.
class ActionPlanCacheMapper {
  /// Maps a remote DTO into a Drift insert companion for the cache table.
  static CachedActionPlansCompanion toCompanion(ActionPlanDto plan) {
    return CachedActionPlansCompanion.insert(
      id: plan.id,
      submissionId: Value(plan.submissionId),
      criteriaLabel: plan.criteriaLabel,
      groupTitle: plan.groupTitle,
      status: Value(plan.status),
      storeName: Value(plan.storeName),
      storeId: Value(plan.storeId),
      storeManagerName: Value(plan.storeManagerName),
      rootCause: Value(plan.rootCause),
      correctionPlan: Value(plan.correctionPlan),
      evidencePhotoUrl: Value(plan.evidencePhotoUrl),
      evidenceNote: Value(plan.evidenceNote),
      closedAt: Value(plan.closedAt),
      verifierName: Value(plan.verifierName),
      evidenceSubmittedAt: Value(plan.evidenceSubmittedAt),
      evidenceSubmittedByName: Value(plan.evidenceSubmittedByName),
      deadline: Value(plan.deadline),
      cachedAllowedActions: Value(encodeAllowedActions(plan.allowedActions)),
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  /// Maps a Drift cache row back into an [ActionPlanDto].
  static ActionPlanDto fromRow(CachedActionPlan row) {
    return ActionPlanDto(
      id: row.id,
      submissionId: row.submissionId,
      status: row.status,
      criteriaLabel: row.criteriaLabel,
      groupTitle: row.groupTitle,
      storeName: row.storeName,
      storeId: row.storeId,
      storeManagerName: row.storeManagerName,
      rootCause: row.rootCause,
      correctionPlan: row.correctionPlan,
      evidencePhotoUrl: row.evidencePhotoUrl,
      evidenceNote: row.evidenceNote,
      closedAt: row.closedAt,
      verifierName: row.verifierName,
      evidenceSubmittedAt: row.evidenceSubmittedAt,
      evidenceSubmittedByName: row.evidenceSubmittedByName,
      deadline: row.deadline,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      allowedActions: decodeAllowedActions(row.cachedAllowedActions),
    );
  }

  static String? encodeAllowedActions(List<String>? actions) {
    if (actions == null) return null;
    return jsonEncode(actions);
  }

  static List<String>? decodeAllowedActions(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<String>().toList();
    } catch (_) {
      return null;
    }
  }
}
