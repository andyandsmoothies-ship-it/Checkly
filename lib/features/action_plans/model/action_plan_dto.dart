/// DTO for an action plan.
///
/// Mirrors the backend ActionPlanDto from server/Features/ActionPlans/Dtos.cs.
class ActionPlanDto {
  final String id;
  final String status; // 'open', 'pending_verify', 'closed'
  final String criteriaLabel;
  final String groupTitle;
  final String? storeName;
  final String? storeId;
  final String? storeManagerName;
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

  const ActionPlanDto({
    required this.id,
    required this.status,
    required this.criteriaLabel,
    required this.groupTitle,
    this.storeName,
    this.storeId,
    this.storeManagerName,
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
  });

  factory ActionPlanDto.fromJson(Map<String, dynamic> json) => ActionPlanDto(
    id: json['id'] as String,
    status: json['status'] as String,
    criteriaLabel: json['criteriaLabel'] as String? ?? '',
    groupTitle: json['groupTitle'] as String? ?? '',
    storeName: json['storeName'] as String?,
    storeId: json['storeId'] as String?,
    storeManagerName: json['storeManagerName'] as String?,
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
  );
}
