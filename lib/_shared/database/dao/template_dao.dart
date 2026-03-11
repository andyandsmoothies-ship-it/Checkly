import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/templates/model/template_dto.dart';

/// DAO for cached template data (templates, groups, criteria).
///
/// Bridges Drift tables ↔ domain DTOs for the cache-first read path.
class TemplateDao {
  final AppDatabase _db;

  TemplateDao(this._db);

  // ---------- Templates ----------

  /// Read all cached templates.
  Future<List<TemplateDto>> getAllTemplates() async {
    final rows = await _db.select(_db.cachedTemplates).get();
    return rows.map(_rowToTemplateDto).toList();
  }

  /// Upsert a batch of templates (full replace).
  Future<void> upsertTemplates(List<TemplateDto> templates) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.cachedTemplates,
        templates.map(_templateToCompanion).toList(),
      );
    });
  }

  // ---------- Groups ----------

  /// Read all cached groups for a template.
  Future<List<CachedGroup>> getGroupsForTemplate(String templateId) async {
    return (_db.select(_db.cachedGroups)
          ..where((g) => g.templateId.equals(templateId))
          ..orderBy([(g) => OrderingTerm.asc(g.orderIndex)]))
        .get();
  }

  /// Upsert groups for a template.
  Future<void> upsertGroups(
    String templateId,
    List<GroupDto> groups,
    String? parentId,
  ) async {
    await _db.batch((b) {
      for (final g in groups) {
        b.insertAllOnConflictUpdate(_db.cachedGroups, [
          CachedGroupsCompanion.insert(
            id: g.id,
            templateId: templateId,
            title: g.title,
            description: Value(g.description),
            weight: Value(g.weight),
            maxDeductionPoints: Value(g.maxDeductionPoints),
            orderIndex: Value(g.orderIndex),
            parentId: Value(parentId),
            metadata: Value(g.metadata),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);
        // Recurse for children
        if (g.children.isNotEmpty) {
          upsertGroups(templateId, g.children, g.id);
        }
        // Upsert criteria for this group
        if (g.criteria.isNotEmpty) {
          upsertCriteria(g.id, g.criteria);
        }
      }
    });
  }

  // ---------- Criteria ----------

  /// Read all cached criteria for a group.
  Future<List<CachedCriteriaData>> getCriteriaForGroup(String groupId) async {
    return (_db.select(_db.cachedCriteria)
          ..where((c) => c.groupId.equals(groupId))
          ..orderBy([(c) => OrderingTerm.asc(c.orderIndex)]))
        .get();
  }

  /// Upsert criteria for a group.
  Future<void> upsertCriteria(
    String groupId,
    List<CriterionDto> criteria,
  ) async {
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.cachedCriteria,
        criteria
            .map(
              (c) => CachedCriteriaCompanion.insert(
                id: c.id,
                groupId: groupId,
                label: c.label,
                description: Value(c.description),
                inputType: c.inputType,
                pointsWeight: Value(c.pointsWeight),
                isCcp: Value(c.isCcp),
                isRisk: Value(c.isRisk),
                orderIndex: Value(c.orderIndex),
                metadata: Value(c.metadata),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList(),
      );
    });
  }

  /// Build a full TemplateTreeDto from cached groups + criteria.
  Future<TemplateTreeDto?> getTemplateTree(String templateId) async {
    final templateRows = await (_db.select(
      _db.cachedTemplates,
    )..where((t) => t.id.equals(templateId))).get();
    if (templateRows.isEmpty) return null;
    final t = templateRows.first;

    final allGroups = await getGroupsForTemplate(templateId);
    final rootGroups = allGroups.where((g) => g.parentId == null).toList();

    Future<List<GroupDto>> buildTree(List<CachedGroup> groups) async {
      final result = <GroupDto>[];
      for (final g in groups) {
        final children = allGroups.where((c) => c.parentId == g.id).toList();
        final criteria = await getCriteriaForGroup(g.id);
        result.add(
          GroupDto(
            id: g.id,
            title: g.title,
            description: g.description,
            weight: g.weight,
            maxDeductionPoints: g.maxDeductionPoints,
            orderIndex: g.orderIndex,
            metadata: g.metadata,
            children: await buildTree(children),
            criteria: criteria
                .map(
                  (c) => CriterionDto(
                    id: c.id,
                    label: c.label,
                    description: c.description,
                    inputType: c.inputType,
                    pointsWeight: c.pointsWeight,
                    isCcp: c.isCcp,
                    isRisk: c.isRisk,
                    orderIndex: c.orderIndex,
                    metadata: c.metadata,
                  ),
                )
                .toList(),
          ),
        );
      }
      return result;
    }

    return TemplateTreeDto(
      id: t.id,
      title: t.title,
      description: t.description,
      type: t.type,
      version: t.version,
      scoringLogicConfig: t.scoringLogicConfig,
      isActive: t.isActive,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
      groups: await buildTree(rootGroups),
    );
  }

  // ---------- Mappers ----------

  TemplateDto _rowToTemplateDto(CachedTemplate row) => TemplateDto(
    id: row.id,
    title: row.title,
    description: row.description,
    type: row.type,
    version: row.version,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  CachedTemplatesCompanion _templateToCompanion(TemplateDto dto) =>
      CachedTemplatesCompanion.insert(
        id: dto.id,
        title: dto.title,
        description: Value(dto.description),
        type: dto.type,
        version: Value(dto.version),
        isActive: Value(dto.isActive),
        scoringLogicConfig: const Value(null),
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );
}
