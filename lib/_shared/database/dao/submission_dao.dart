import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/audit/model/submission_dto.dart';

/// DAO for cached submission history.
class SubmissionDao {
  final AppDatabase _db;

  SubmissionDao(this._db);

  /// Read all cached submissions.
  Future<List<SubmissionDto>> getAllSubmissions() async {
    final rows =
        await (_db.select(_db.cachedSubmissions)
              ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
              ..limit(500))
            .get();
    return rows.map(SubmissionDao.rowToDto).toList();
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

  /// Reads cached template/store metadata for locally-hydrated history rows.
  Future<({String? templateTitle, String? templateType, String? storeName})>
  getLocalOverrideMetadata(String templateId, String storeId) async {
    final template = await (_db.select(
      _db.cachedTemplates,
    )..where((t) => t.id.equals(templateId))).getSingleOrNull();
    final store = await (_db.select(
      _db.cachedStores,
    )..where((s) => s.id.equals(storeId))).getSingleOrNull();

    return (
      templateTitle: template?.title,
      templateType: template?.type,
      storeName: store?.name,
    );
  }

  /// Reads the saved-at timestamp for a local draft key, if present.
  Future<DateTime?> getDraftSavedAt(String draftKey) async {
    final draft = await (_db.select(
      _db.draftAnswers,
    )..where((d) => d.draftKey.equals(draftKey))).getSingleOrNull();
    return draft?.savedAt;
  }

  // ---------- Mappers ----------

  static SubmissionDto rowToDto(CachedSubmission row) => SubmissionDto(
    id: row.id,
    templateId: row.templateId,
    templateTitle: row.templateTitle,
    templateType: row.templateType,
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
        templateType: Value(dto.templateType),
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
