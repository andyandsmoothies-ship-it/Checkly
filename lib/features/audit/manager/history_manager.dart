import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/submission_dao.dart';
import '../model/submission_dto.dart';
import '../services/draft_service.dart';
import '../services/submission_api_service.dart';
import '../../../_shared/database/dao/outbox_dao.dart';

final _di = GetIt.instance;

/// PFA Manager for audit history — cache-first read path with pagination.
///
/// `loadHistory()`: resets to page 1 (initial + pull-to-refresh)
/// `loadMore()`: loads next page and appends results
class HistoryManager extends ChangeNotifier {
  final SubmissionApiService _api;
  late final SubmissionDao _dao;
  late final DraftService _draftService;
  late final OutboxDao _outboxDao;

  HistoryManager({
    SubmissionApiService? api,
    SubmissionDao? dao,
    DraftService? draftService,
    OutboxDao? outboxDao,
  }) : _api = api ?? _di<SubmissionApiService>() {
    if (dao != null) {
      _dao = dao;
    } else {
      _dao = SubmissionDao(_di<DatabaseService>().db);
    }
    _draftService = draftService ?? DraftService();
    _outboxDao = outboxDao ?? OutboxDao(_di<DatabaseService>().db);
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
        submissions.value = await _applyLocalOverrides(cached);
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch (page 1)
      try {
        final fresh = await _api.getSubmissions(page: 1, pageSize: _pageSize);
        submissions.value = await _applyLocalOverrides(fresh);
        hasMore = fresh.length >= _pageSize;
        lastRefreshed = DateTime.now();

        // 3. Update Drift cache (store raw server data — overrides are in-memory only)
        await _dao.upsertSubmissions(fresh);
      } catch (_) {
        if (cached.isEmpty) {
          error = 'Failed to load audit history (offline)';
        }
      }
    } catch (_) {
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
      final hydrated = await _applyLocalOverrides(more);
      submissions.value = [...submissions.value, ...hydrated];
      hasMore = more.length >= _pageSize;
    } catch (_) {
      _page--; // Revert on failure so retry works
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ---------- Start Scheduled Audit (scheduled → draft) ----------
  Future<SubmissionDto> startScheduledAudit(String submissionId) async {
    final updated = await _api.updateSubmission(submissionId, {
      'status': 'draft',
    });

    // Update local list
    final list = List<SubmissionDto>.from(submissions.value);
    final idx = list.indexWhere((s) => s.id == submissionId);
    if (idx >= 0) {
      list[idx] = updated;
      submissions.value = list;
    }
    notifyListeners();
    return updated;
  }

  // ---------- Void Audit (admin-only) ----------
  Future<void> voidAudit(String submissionId, String reason) async {
    await _api.voidSubmission(submissionId, reason);

    // Surgically update the in-memory list — no full reload needed.
    final list = List<SubmissionDto>.from(submissions.value);
    final idx = list.indexWhere((s) => s.id == submissionId);
    if (idx >= 0) {
      list[idx] = list[idx].withStatus('voided');
      submissions.value = list;
    }
    notifyListeners();
  }

  // ---------- Cloud Archive (GC Pillar A) ----------

  /// Whether the 90-day archive contains remote records not present in local cache.
  final hasArchivedRecords = ValueNotifier<bool>(false);

  /// Results returned by the last successful cloud archive search.
  final archivedSubmissions = ValueNotifier<List<SubmissionDto>>([]);

  /// Non-null when the last archive search failed.
  String? archiveError;

  /// Queries the server for audits whose terminal event occurred > 90 days ago.
  /// On success: populates [archivedSubmissions] and sets [hasArchivedRecords].
  /// On failure: sets [archiveError]; [hasArchivedRecords] is deliberately preserved
  /// so the banner stays visible (per spec AC5c — banner persists on network failure).
  Future<void> searchCloudArchive() async {
    archiveError = null;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final results = await _api.searchArchive(before: cutoff);
      archivedSubmissions.value = results;
      hasArchivedRecords.value = results.isNotEmpty;
    } catch (e) {
      archiveError = 'Failed to load archive: $e';
      // hasArchivedRecords intentionally NOT reset — banner must persist.
    } finally {
      notifyListeners();
    }
  }

  // ---------- Local Draft Hydration ----------

  /// Merges device-local SQLite draft state into a list of server DTOs.
  ///
  /// For each submission whose server status is still `'scheduled'`, checks
  /// whether a local draft exists by prefix-matching the draft key:
  ///   `"${s.templateId}:${s.storeId}:"`
  /// If a match is found, overrides the status to `'draft'` in-memory.
  /// Also injects any pending submissions from the outbox queue.
  /// The Drift cache is intentionally NOT updated — only the live in-memory
  /// list is patched, ensuring the server remains the source of truth on disk.
  Future<List<SubmissionDto>> _applyLocalOverrides(
    List<SubmissionDto> list,
  ) async {
    final draftKeys = await _draftService.getAllDraftKeys();
    if (draftKeys.isEmpty) return list;

    final List<SubmissionDto> result = [];
    final Set<String> processedDraftKeys = {};

    for (final s in list) {
      if (s.status != 'scheduled') {
        result.add(s);
        continue;
      }
      final tId = s.templateId;
      final sId = s.storeId;
      if (tId == null || sId == null) {
        result.add(s);
        continue;
      }
      final prefix = '$tId:$sId:';
      final matchedKey = draftKeys
          .cast<String?>()
          .firstWhere((k) => k!.startsWith(prefix), orElse: () => null);

      if (matchedKey != null) {
        result.add(s.withStatus('draft'));
        processedDraftKeys.add(matchedKey);
      } else {
        result.add(s);
      }
    }

    // Inject purely local ad-hoc drafts that have no server counterpart
    final unseenKeys =
        draftKeys.where((k) => !processedDraftKeys.contains(k)).toList();

    if (unseenKeys.isNotEmpty) {
      final db = _di<DatabaseService>().db;
      for (final key in unseenKeys) {
        final parts = key.split(':');
        if (parts.length >= 2) {
          final tId = parts[0];
          final sId = parts[1];
          String? tTitle;
          String? sName;
          DateTime savedAt = DateTime.now();

          try {
            final tRow = await (db.select(db.cachedTemplates)
                  ..where((t) => t.id.equals(tId)))
                .getSingleOrNull();
            if (tRow != null) tTitle = tRow.title;

            final sRow = await (db.select(db.cachedStores)
                  ..where((s) => s.id.equals(sId)))
                .getSingleOrNull();
            if (sRow != null) sName = sRow.name;

            final dRow = await (db.select(db.draftAnswers)
                  ..where((d) => d.draftKey.equals(key)))
                .getSingleOrNull();
            if (dRow != null) savedAt = dRow.savedAt;
          } catch (_) {}

          result.insert(
            0,
            SubmissionDto(
              id: 'local_draft_$key',
              templateId: tId,
              templateTitle: tTitle ?? 'Draft Audit',
              storeId: sId,
              storeName: sName ?? 'Unknown Store',
              status: 'draft',
              createdAt: savedAt,
            ),
          );
        }
      }
    }

    // Inject outbox pending submissions
    final pendingRows = await _outboxDao.getAllPending();
    if (pendingRows.isNotEmpty) {
      final db = _di<DatabaseService>().db;
      for (final p in pendingRows) {
        // Remove the original row if this pending outbox is finalizing it
        if (p.targetSubmissionId != null) {
          result.removeWhere((s) => s.id == p.targetSubmissionId);
        }

        String? tTitle;
        String? sName;
        try {
          final tRow = await (db.select(db.cachedTemplates)
                ..where((t) => t.id.equals(p.templateId)))
              .getSingleOrNull();
          if (tRow != null) tTitle = tRow.title;

          final sRow = await (db.select(db.cachedStores)
                ..where((s) => s.id.equals(p.storeId)))
              .getSingleOrNull();
          if (sRow != null) sName = sRow.name;
        } catch (_) {}

        result.insert(
          0,
          SubmissionDto(
            id: 'local_outbox_${p.id}',
            templateId: p.templateId,
            templateTitle: tTitle ?? 'Audit',
            storeId: p.storeId,
            storeName: sName ?? 'Unknown Store',
            status: p.syncStatus == 'pending' ? 'syncing' : (p.syncStatus == 'exhausted' ? 'failed' : 'syncing'),
            createdAt: p.createdAt,
            totalScore: p.clientScore,
          ),
        );
      }
    }

    // Sort combined feed
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }
}
