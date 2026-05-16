import '../../../_shared/constants/action_plan_actions.dart';

List<String>? _parseAllowedActions(dynamic value) {
  if (value == null) return null;
  if (value is! List) return null;
  return value.whereType<String>().toList();
}

/// DTO for an action plan.
///
/// Mirrors the backend ActionPlanDto from server/Features/ActionPlans/Dtos.cs.
class ActionPlanDto {
  final String id;
  final String? submissionId;
  final String status; // 'open', 'pending_verify', 'closed'
  final String criteriaLabel;
  final String groupTitle;
  final String? storeName;
  final String? storeId;
  final String? storeManagerName;
  final String? sourceTitle;
  final String? rootCause;
  final String? correctionPlan;
  final String? evidencePhotoUrl;
  final String? evidenceNote;
  final DateTime? closedAt;
  final String? verifierName;
  final DateTime? evidenceSubmittedAt;
  final String? evidenceSubmittedByName;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? allowedActions;
  final String? syncStatus;

  const ActionPlanDto({
    required this.id,
    this.submissionId,
    required this.status,
    required this.criteriaLabel,
    required this.groupTitle,
    this.storeName,
    this.storeId,
    this.storeManagerName,
    this.sourceTitle,
    this.rootCause,
    this.correctionPlan,
    this.evidencePhotoUrl,
    this.evidenceNote,
    this.closedAt,
    this.verifierName,
    this.evidenceSubmittedAt,
    this.evidenceSubmittedByName,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.allowedActions,
    this.syncStatus,
  });

  factory ActionPlanDto.fromJson(Map<String, dynamic> json) => ActionPlanDto(
    id: json['id'] as String,
    submissionId: json['submissionId'] as String?,
    status: json['status'] as String,
    criteriaLabel: json['criteriaLabel'] as String? ?? '',
    groupTitle: json['groupTitle'] as String? ?? '',
    storeName: json['storeName'] as String?,
    storeId: json['storeId'] as String?,
    storeManagerName: json['storeManagerName'] as String?,
    sourceTitle: json['sourceTitle'] as String?,
    rootCause: json['rootCause'] as String?,
    correctionPlan: json['correctionPlan'] as String?,
    evidencePhotoUrl: json['evidencePhotoUrl'] as String?,
    evidenceNote: json['evidenceNote'] as String?,
    closedAt: json['closedAt'] != null
        ? DateTime.parse(json['closedAt'] as String)
        : null,
    verifierName: json['verifierName'] as String?,
    evidenceSubmittedAt: json['evidenceSubmittedAt'] != null
        ? DateTime.parse(json['evidenceSubmittedAt'] as String)
        : null,
    evidenceSubmittedByName: json['evidenceSubmittedByName'] as String?,
    deadline: json['deadline'] != null
        ? DateTime.parse(json['deadline'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    allowedActions: _parseAllowedActions(json['allowedActions']),
  );

  factory ActionPlanDto.offline({
    required String id,
    required String criteriaLabel,
    required String groupTitle,
    String status = 'open',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ActionPlanDto(
      id: id,
      status: status,
      criteriaLabel: criteriaLabel,
      groupTitle: groupTitle,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      allowedActions: const [
        ActionPlanActions.view,
        ActionPlanActions.edit,
        ActionPlanActions.delete,
      ],
      syncStatus: 'pending',
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'submissionId': submissionId,
    'status': status,
    'criteriaLabel': criteriaLabel,
    'groupTitle': groupTitle,
    'storeName': storeName,
    'storeId': storeId,
    'storeManagerName': storeManagerName,
    'sourceTitle': sourceTitle,
    'rootCause': rootCause,
    'correctionPlan': correctionPlan,
    'evidencePhotoUrl': evidencePhotoUrl,
    'evidenceNote': evidenceNote,
    'closedAt': closedAt?.toIso8601String(),
    'verifierName': verifierName,
    'evidenceSubmittedAt': evidenceSubmittedAt?.toIso8601String(),
    'evidenceSubmittedByName': evidenceSubmittedByName,
    'deadline': deadline?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'allowedActions': allowedActions,
    'syncStatus': syncStatus,
  };
}
