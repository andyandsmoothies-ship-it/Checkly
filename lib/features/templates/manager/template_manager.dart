import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/template_dao.dart';
import '../models/template_dto.dart';
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
    } catch (_) {
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

  // ---------- Save template (atomic tree save) ----------
  /// Saves the full template tree atomically via PUT /templates/{id}/tree.
  /// For new templates: creates first, then saves the tree.
  /// Returns the final template ID.
  Future<String> saveTemplate({
    String? id,
    required String title,
    required String type,
    String? description,
    String? scoringLogicConfig,
    String? displayNoun,
    int version = 0,
    List<Map<String, dynamic>> groups = const [],
  }) async {
    String templateId;

    if (id == null || id.isEmpty || id == 'new') {
      // Create new template first (gets us the ID)
      final result = await _api.createTemplate(
        title: title,
        type: type,
        description: description,
        scoringLogicConfig: scoringLogicConfig,
      );
      templateId = result['id'] as String;
      // Sync the server-initialized version (server sets Version = 1 on creation)
      version = result['version'] as int;
    } else {
      templateId = id;
    }

    // Save the full tree atomically
    try {
      await _api.saveTemplateTree(
        templateId,
        title: title,
        type: type,
        description: description,
        scoringLogicConfig: scoringLogicConfig,
        displayNoun: displayNoun,
        version: version,
        groups: groups,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
          'This template was modified by another user. '
          'Please reload the template and try again.',
        );
      }
      rethrow;
    }

    // Refresh list
    await loadTemplates();
    return templateId;
  }

  // ---------- Delete template ----------
  Future<void> deleteTemplate(String id) async {
    await _api.deleteTemplate(id);
    templates.value = templates.value.where((t) => t.id != id).toList();
    notifyListeners();
  }

  // ---------- Duplicate template ----------
  Future<TemplateDto> duplicateTemplate(String id) async {
    final cloned = await _api.cloneTemplate(id);
    templates.value = [...templates.value, cloned];
    notifyListeners();
    return cloned;
  }
}
