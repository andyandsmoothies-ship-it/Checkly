import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/submission_dao.dart';
import '../model/submission_dto.dart';
import '../services/submission_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for audit history — cache-first read path.
///
/// `loadHistory()`:
/// 1. Read from Drift cache → emit immediately
/// 2. Background API fetch → update Drift → notify listeners
class HistoryManager extends ChangeNotifier {
  final SubmissionApiService _api;
  late final SubmissionDao _dao;

  HistoryManager({SubmissionApiService? api, SubmissionDao? dao})
    : _api = api ?? _di<SubmissionApiService>() {
    final db = _di<DatabaseService>().db;
    _dao = dao ?? SubmissionDao(db);
  }

  // ---------- State ----------
  final submissions = ValueNotifier<List<SubmissionDto>>([]);
  final isLoading = ValueNotifier<bool>(false);
  String? error;
  DateTime? lastRefreshed;

  // ---------- Load (cache-first) ----------
  Future<void> loadHistory() async {
    isLoading.value = true;
    error = null;
    notifyListeners();

    try {
      // 1. Read from Drift cache first
      final cached = await _dao.getAllSubmissions();
      if (cached.isNotEmpty) {
        submissions.value = cached;
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch
      try {
        final fresh = await _api.getSubmissions();
        submissions.value = fresh;
        lastRefreshed = DateTime.now();

        // 3. Update Drift cache
        await _dao.upsertSubmissions(fresh);
      } catch (_) {
        if (cached.isEmpty) {
          error = 'Failed to load audit history (offline)';
        }
      }
    } catch (e) {
      error = 'Failed to load audit history';
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }
}
