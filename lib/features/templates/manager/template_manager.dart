import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/template_dao.dart';
import '../model/template_dto.dart';
import '../services/template_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for templates — cache-first read path.
///
/// `loadTemplates()`:
/// 1. Read from Drift cache → emit immediately
/// 2. Background API fetch → update Drift → notify listeners
///
/// Works offline: shows cached data. Shows API data when online.
class TemplateManager extends ChangeNotifier {
  final TemplateApiService _api;
  late final TemplateDao _dao;

  TemplateManager({TemplateApiService? api, TemplateDao? dao})
    : _api = api ?? _di<TemplateApiService>() {
    final db = _di<DatabaseService>().db;
    _dao = dao ?? TemplateDao(db);
  }

  // ---------- State ----------
  final templates = ValueNotifier<List<TemplateDto>>([]);
  final selectedTemplate = ValueNotifier<TemplateTreeDto?>(null);
  final isLoading = ValueNotifier<bool>(false);
  String? error;
  DateTime? lastRefreshed;

  /// Defers notifyListeners to after the current frame if we're mid-build.
  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ---------- Load list (cache-first) ----------
  Future<void> loadTemplates() async {
    isLoading.value = true;
    error = null;
    notifyListeners();

    try {
      // 1. Read from Drift cache first
      final cached = await _dao.getAllTemplates();
      if (cached.isNotEmpty) {
        templates.value = cached;
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch
      try {
        final fresh = await _api.getTemplates();
        templates.value = fresh;
        lastRefreshed = DateTime.now();

        // 3. Update Drift cache
        await _dao.upsertTemplates(fresh);
      } catch (_) {
        // API failed — use cached data silently
        if (cached.isEmpty) {
          error = 'Failed to load templates (offline)';
        }
      }
    } catch (e) {
      error = 'Failed to load templates';
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  // ---------- Load tree (cache-first) ----------
  Future<void> loadTemplateTree(String id) async {
    isLoading.value = true;
    error = null;
    _safeNotify();

    try {
      // 1. Try Drift cache first
      final cached = await _dao.getTemplateTree(id);
      if (cached != null) {
        selectedTemplate.value = cached;
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch
      try {
        final fresh = await _api.getTemplateTree(id);
        selectedTemplate.value = fresh;

        // 3. Update Drift cache (template + groups + criteria)
        await _dao.upsertTemplates([
          TemplateDto(
            id: fresh.id,
            title: fresh.title,
            description: fresh.description,
            type: fresh.type,
            version: fresh.version,
            scoringLogicConfig: fresh.scoringLogicConfig,
            isActive: fresh.isActive,
            createdAt: fresh.createdAt,
            updatedAt: fresh.updatedAt,
          ),
        ]);
        await _dao.upsertGroups(id, fresh.groups, null);
      } catch (_) {
        if (cached == null) {
          error = 'Failed to load template details (offline)';
        }
      }
    } catch (e) {
      error = 'Failed to load template details';
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  // ---------- Save template (create or update) ----------
  Future<String> saveTemplate({
    String? id,
    required String title,
    required String type,
    String? description,
    String? scoringLogicConfig,
    List<GroupDto> groups = const [],
  }) async {
    String templateId;

    if (id == null || id.isEmpty || id == 'new') {
      // Create new
      final result = await _api.createTemplate(
        title: title,
        type: type,
        description: description,
        scoringLogicConfig: scoringLogicConfig,
      );
      templateId = result['id'] as String;
    } else {
      // Update existing
      await _api.updateTemplate(
        id,
        title: title,
        type: type,
        description: description,
        scoringLogicConfig: scoringLogicConfig,
      );
      templateId = id;
    }

    // Save groups recursively
    for (var i = 0; i < groups.length; i++) {
      await _saveGroupRecursive(templateId, groups[i], i, null);
    }

    // Refresh list
    await loadTemplates();
    return templateId;
  }

  Future<void> _saveGroupRecursive(
    String templateId,
    GroupDto group,
    int orderIndex,
    String? parentId,
  ) async {
    String groupId;

    if (group.id.isEmpty) {
      // New group
      final result = await _api.createGroup(
        templateId,
        title: group.title,
        description: group.description,
        weight: group.weight,
        maxDeductionPoints: group.maxDeductionPoints,
        minusPerFault: group.minusPerFault,
        orderIndex: orderIndex,
        parentId: parentId,
        metadata: group.metadata,
      );
      groupId = result['id'] as String;
    } else {
      // Existing group
      await _api.updateGroup(
        templateId,
        group.id,
        title: group.title,
        description: group.description,
        weight: group.weight,
        maxDeductionPoints: group.maxDeductionPoints,
        minusPerFault: group.minusPerFault,
        orderIndex: orderIndex,
        metadata: group.metadata,
      );
      groupId = group.id;
    }

    // Save criteria
    for (var i = 0; i < group.criteria.length; i++) {
      final c = group.criteria[i];
      if (c.id.isEmpty) {
        await _api.createCriterion(
          templateId,
          groupId,
          label: c.label,
          inputType: c.inputType,
          description: c.description,
          pointsWeight: c.pointsWeight,
          isCcp: c.isCcp,
          isRisk: c.isRisk,
          orderIndex: i,
        );
      } else {
        await _api.updateCriterion(
          templateId,
          c.id,
          label: c.label,
          inputType: c.inputType,
          description: c.description,
          pointsWeight: c.pointsWeight,
          isCcp: c.isCcp,
          isRisk: c.isRisk,
          orderIndex: i,
        );
      }
    }

    // Save children recursively
    for (var i = 0; i < group.children.length; i++) {
      await _saveGroupRecursive(templateId, group.children[i], i, groupId);
    }
  }

  // ---------- Delete template ----------
  Future<void> deleteTemplate(String id) async {
    await _api.deleteTemplate(id);
    templates.value = templates.value.where((t) => t.id != id).toList();
    notifyListeners();
  }

  // ---------- Delete group ----------
  Future<void> deleteGroup(String templateId, String groupId) async {
    await _api.deleteGroup(templateId, groupId);
  }

  // ---------- Delete criterion ----------
  Future<void> deleteCriterion(String templateId, String criterionId) async {
    await _api.deleteCriterion(templateId, criterionId);
  }
}
