import 'package:flutter/foundation.dart';
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
    notifyListeners();

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
}
