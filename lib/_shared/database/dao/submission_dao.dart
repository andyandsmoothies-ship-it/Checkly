import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/audit/model/submission_dto.dart';

/// DAO for cached submission history.
class SubmissionDao {
  final AppDatabase _db;

  SubmissionDao(this._db);

  /// Read all cached submissions.
  Future<List<SubmissionDto>> getAllSubmissions() async {
    final rows = await (_db.select(
      _db.cachedSubmissions,
    )..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
    return rows.map(_rowToDto).toList();
  }

  /// Upsert a batch of submissions.
  Future<void> upsertSubmissions(List<SubmissionDto> submissions) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.cachedSubmissions,
        submissions.map(_dtoToCompanion).toList(),
      );
    });
  }

  // ---------- Mappers ----------

  SubmissionDto _rowToDto(CachedSubmission row) => SubmissionDto(
    id: row.id,
    templateId: row.templateId,
    templateTitle: row.templateTitle,
    storeId: row.storeId,
    storeName: row.storeName,
    auditorId: row.auditorId,
    auditorName: row.auditorName,
    status: row.status,
    totalScore: row.totalScore,
    sectionScores: row.sectionScores,
    notes: row.notes,
    createdAt: row.createdAt,
    completedAt: row.completedAt,
    templateSnapshot: row.templateSnapshot,
    templateVersion: row.templateVersion,
    voidReason: row.voidReason,
    voidedAt: row.voidedAt,
  );

  CachedSubmissionsCompanion _dtoToCompanion(SubmissionDto dto) =>
      CachedSubmissionsCompanion.insert(
        id: dto.id,
        templateId: Value(dto.templateId),
        templateTitle: Value(dto.templateTitle),
        storeId: Value(dto.storeId),
        storeName: Value(dto.storeName),
        auditorId: Value(dto.auditorId),
        auditorName: Value(dto.auditorName),
        status: dto.status,
        totalScore: Value(dto.totalScore),
        sectionScores: Value(dto.sectionScores),
        notes: Value(dto.notes),
        createdAt: dto.createdAt,
        completedAt: Value(dto.completedAt),
        templateSnapshot: Value(dto.templateSnapshot),
        templateVersion: Value(dto.templateVersion),
        voidReason: Value(dto.voidReason),
        voidedAt: Value(dto.voidedAt),
      );
}
