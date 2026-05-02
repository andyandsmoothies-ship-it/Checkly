import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/dao/program_outbox_dao.dart';
import '../model/program_assignment_dto.dart';

// ============================================================
// ProgramManager — offline-first assignment reader + evidence writer
// ============================================================

/// Manages the SM's program assignment lifecycle.
///
/// Design: offline-first.
/// - [loadAssignments] reads from the local Drift cache (populated by SyncEngine).
/// - [submitEvidence] writes to the outbox (PendingProgramSubmissions + optional photo).
///   An optimistic update marks the cached assignment as `submitted` immediately,
///   so the UI hides the task before the network round-trip completes.
class ProgramManager extends ChangeNotifier {
  final ProgramOutboxDao _outboxDao;

  ProgramManager({required ProgramOutboxDao outboxDao})
    : _outboxDao = outboxDao;

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

  // ---------- Mutations ----------

  /// Submit evidence for an assignment — writes to the offline outbox.
  ///
  /// Steps:
  /// 1. Validates [note] is not empty (business rule — UI should also guard this).
  /// 2. Enqueues a [PendingProgramSubmissionsCompanion] row.
  /// 3. If [photoPath] is provided, enqueues a [PendingProgramPhotosCompanion] row.
  /// 4. Optimistically marks the assignment status as `submitted` in the cache.
  /// 5. Removes the assignment from [assignments.value] in-memory.
  ///
  /// Throws [ArgumentError] if [note] is empty.
  Future<void> submitEvidence(
    String assignmentId,
    String note, {
    String? photoPath,
  }) async {
    if (note.trim().isEmpty) {
      throw ArgumentError('Note must not be empty');
    }

    final submissionId = const Uuid().v4();
    final photoLocalKey = photoPath != null ? const Uuid().v4() : null;

    // 1. Write evidence outbox row.
    await _outboxDao.enqueue(
      PendingProgramSubmissionsCompanion.insert(
        id: submissionId,
        assignmentId: assignmentId,
        evidenceItemsJson: jsonEncode([
          {
            'criteriaId': 'program_summary',
            'value': note.trim(),
            'photoLocalKey': photoLocalKey,
          },
        ]),
        createdAt: DateTime.now().toUtc(),
      ),
    );

    // 2. Write photo outbox row (if provided).
    if (photoPath != null && photoLocalKey != null) {
      await _outboxDao.enqueuePhoto(
        PendingProgramPhotosCompanion.insert(
          id: photoLocalKey,
          pendingProgramSubmissionId: submissionId,
          criteriaId: 'program_summary',
          localPath: photoPath,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }

    // 3. Optimistic update: mark as submitted in local cache.
    await _outboxDao.upsertCachedAssignment(
      CachedProgramAssignmentsCompanion(
        id: Value(assignmentId),
        status: const Value('submitted'),
      ),
    );

    // 4. Remove from in-memory list so UI refreshes immediately.
    assignments.value = assignments.value
        .where((a) => a.id != assignmentId)
        .toList();

    debugPrint(
      '[ProgramManager] submitEvidence: assignment=$assignmentId '
      'submission=$submissionId photo=${photoLocalKey ?? "none"}',
    );

    notifyListeners();
  }
}
