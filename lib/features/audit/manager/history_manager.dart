import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/submission_dao.dart';
import '../model/submission_dto.dart';
import '../services/submission_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for audit history — cache-first read path with pagination.
///
/// `loadHistory()`: resets to page 1 (initial + pull-to-refresh)
/// `loadMore()`: loads next page and appends results
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

  // Pagination state
  int _page = 1;
  static const int _pageSize = 50;
  bool hasMore = true;
  bool isLoadingMore = false;

  // ---------- Load (cache-first, page 1) ----------
  Future<void> loadHistory() async {
    _page = 1;
    hasMore = true;
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

      // 2. Background API fetch (page 1)
      try {
        final fresh = await _api.getSubmissions(page: 1, pageSize: _pageSize);
        submissions.value = fresh;
        hasMore = fresh.length >= _pageSize;
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

  // ---------- Load More (next page, append) ----------
  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final more = await _api.getSubmissions(page: _page, pageSize: _pageSize);
      submissions.value = [...submissions.value, ...more];
      hasMore = more.length >= _pageSize;
    } catch (_) {
      _page--; // Revert on failure so retry works
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}
