import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../_shared/database/dao/program_outbox_dao.dart';
import '../model/program_assignment_dto.dart';
import '../services/program_api_service.dart';

// ============================================================
// ProgramManager — offline-first assignment reader + evidence writer
// ============================================================

/// Manages the SM's program assignment lifecycle.
///
/// Design: offline-first.
/// - [loadAssignments] reads from the local Drift cache (populated by SyncEngine).
/// - Submission writing has been migrated to standard audit forms (Slice 4).
class ProgramManager extends ChangeNotifier {
  final ProgramOutboxDao _outboxDao;
  final ProgramApiService _api;

  ProgramManager({
    required ProgramOutboxDao outboxDao,
    required ProgramApiService api,
  }) : _outboxDao = outboxDao,
       _api = api;

  // ---------- State ----------

  final assignments = ValueNotifier<List<ProgramAssignmentDto>>([]);
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? error;

  // ---------- Queries ----------

  /// Load all non-submitted assignments from the local cache.
  ///
  /// Orders by deadline ASC so the most urgent task is shown first.
  Future<void> loadAssignments() async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rows = await _outboxDao.getNonSubmittedAssignments();
      assignments.value = rows.map(ProgramAssignmentDto.fromDb).toList();
    } catch (e) {
      error = 'Failed to load assignments';
      debugPrint('[ProgramManager] loadAssignments error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Find a single cached assignment by ID (used by ProgramExecutionPage).
  ///
  /// Returns `null` if the assignment is not in the local cache.
  Future<ProgramAssignmentDto?> loadAssignment(String assignmentId) async {
    final row = await _outboxDao.getCachedAssignment(assignmentId);
    return row == null ? null : ProgramAssignmentDto.fromDb(row);
  }

  /// Returns the ID of the SM's primary store from the local cache.
  ///
  /// Delegates to [ProgramOutboxDao] — the page must NOT access the DB directly.
  Future<String> getPrimaryStoreId() => _outboxDao.getPrimaryStoreId();

  // ---------- HQ / Online Queries ----------

  /// Loads live assignment details for the dashboard (HQ-only, online).
  Future<AssignmentDetailPagedResponse> getDashboardAssignments(
    String programId, {
    String? status,
    int page = 1,
  }) => _api.getProgramAssignments(programId, status: status, page: page);

  /// Loads live aggregated summary for the dashboard (HQ-only, online).
  Future<ProgramSummaryResponse> getDashboardSummary(String programId) =>
      _api.getProgramSummary(programId);
}
