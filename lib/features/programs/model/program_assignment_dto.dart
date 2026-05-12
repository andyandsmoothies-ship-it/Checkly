/// UI-friendly representation of a program assignment, mapped from the local
/// Drift cache ([CachedProgramAssignment]).
///
/// This DTO breaks the DB boundary: [ProgramManager] and
/// [ProgramExecutionPage] must import THIS class, not the raw Drift type,
/// so the feature's Pages remain independent of the database layer.
///
/// Naming: `Dto` suffix is used for all data-transfer objects in this project
/// (see `action_plan_dto.dart`). The `fromDb` factory marks it as a
/// DB-to-UI mapping rather than an API-to-UI mapping.
library;

import '../../../_shared/database/app_database.dart';

class ProgramAssignmentDto {
  final String id;
  final String programId;
  final String programTitle;
  final String category;
  final String? templateId;
  final String? activeSubmissionId;
  final DateTime? deadline;
  final String status;
  final String? rejectionComment;
  final DateTime createdAt;

  const ProgramAssignmentDto({
    required this.id,
    required this.programId,
    required this.programTitle,
    required this.category,
    required this.templateId,
    required this.activeSubmissionId,
    required this.deadline,
    required this.status,
    required this.rejectionComment,
    required this.createdAt,
  });

  /// Maps a Drift [CachedProgramAssignment] row to this DTO.
  ///
  /// This factory is the ONLY place in the feature that touches the DB type.
  /// All callers above the Manager layer receive [ProgramAssignmentDto].
  factory ProgramAssignmentDto.fromDb(CachedProgramAssignment db) {
    return ProgramAssignmentDto(
      id: db.id,
      programId: db.programId,
      programTitle: db.programTitle,
      category: db.category,
      templateId: db.templateId,
      activeSubmissionId: db.activeSubmissionId,
      deadline: db.deadline,
      status: db.status,
      rejectionComment: db.rejectionComment,
      createdAt: db.createdAt,
    );
  }
}
