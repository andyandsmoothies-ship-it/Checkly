import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/database_service.dart';
import 'package:get_it/get_it.dart';

/// Manages auto-save drafts for in-progress audits.
///
/// Debounces saves by 3 seconds after each answer change.
/// Drafts expire after 14 days (336 hours) and are cleaned on startup.
class DraftService {
  final AppDatabase _db;
  Timer? _debounceTimer;

  DraftService() : _db = GetIt.instance<DatabaseService>().db;

  /// Schedules a debounced save (3s delay).
  /// Cancels any pending save before scheduling a new one.
  void scheduleSave({
    required String draftKey,
    required Map<String, Map<String, dynamic>> answersMap,
    String? notes,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      await _upsert(draftKey, answersMap, notes);
    });
  }

  /// Forces an immediate save and cancels any pending debounce.
  Future<void> flushSave({
    required String draftKey,
    required Map<String, Map<String, dynamic>> answersMap,
    String? notes,
  }) async {
    _debounceTimer?.cancel();
    await _upsert(draftKey, answersMap, notes);
  }

  /// Loads an existing draft if available and not expired.
  Future<DraftData?> loadDraft(String draftKey) async {
    final row = await (_db.select(
      _db.draftAnswers,
    )..where((t) => t.draftKey.equals(draftKey))).getSingleOrNull();

    if (row == null) return null;

    // Check 14-day (336h) expiry — per ADR-001
    if (DateTime.now().difference(row.savedAt).inHours >= 336) {
      await deleteDraft(draftKey);
      return null;
    }

    try {
      final map = (jsonDecode(row.answersJson) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
      return DraftData(
        answersMap: map,
        notes: row.notesJson,
        savedAt: row.savedAt,
      );
    } catch (_) {
      // Corrupted draft — discard
      await deleteDraft(draftKey);
      return null;
    }
  }

  /// Cancels any pending save and deletes the draft.
  Future<void> deleteDraft(String draftKey) async {
    _debounceTimer?.cancel();
    await (_db.delete(
      _db.draftAnswers,
    )..where((t) => t.draftKey.equals(draftKey))).go();
  }

  /// Deletes all drafts older than 14 days (336 hours) — per ADR-001.
  Future<int> cleanExpired() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 336));
    return await (_db.delete(
      _db.draftAnswers,
    )..where((t) => t.savedAt.isSmallerThanValue(cutoff))).go();
  }

  /// Cancels any pending debounce timer.
  void dispose() {
    _debounceTimer?.cancel();
  }

  /// Returns all raw draft keys currently stored in SQLite.
  ///
  /// Keys follow the format `"templateId:storeId:userId"`.
  /// Used by [HistoryManager] to overlay local draft state onto
  /// the remote API submission list without a full deserialization pass.
  Future<Set<String>> getAllDraftKeys() async {
    final rows = await _db.select(_db.draftAnswers).get();
    return rows.map((r) => r.draftKey).toSet();
  }

  // ── Private ──

  Future<void> _upsert(
    String draftKey,
    Map<String, Map<String, dynamic>> answersMap,
    String? notes,
  ) async {
    await _db
        .into(_db.draftAnswers)
        .insertOnConflictUpdate(
          DraftAnswersCompanion.insert(
            draftKey: draftKey,
            answersJson: jsonEncode(answersMap),
            notesJson: Value(notes),
            savedAt: DateTime.now(),
          ),
        );
  }
}

/// Data class for a loaded draft.
class DraftData {
  final Map<String, Map<String, dynamic>> answersMap;
  final String? notes;
  final DateTime savedAt;

  const DraftData({
    required this.answersMap,
    this.notes,
    required this.savedAt,
  });
}
