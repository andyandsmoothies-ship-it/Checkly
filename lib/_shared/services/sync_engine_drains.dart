part of 'sync_engine.dart';

// ============================================================
// SyncEngine — Drain & Pull methods (extracted for file-size compliance)
// Part of sync_engine.dart library. Has full access to private members.
// ============================================================

extension _SyncEngineDrains on SyncEngine {
  Future<void> _pullDeltas() async {
    lastSyncTimestamp ??= await _syncMetaDao.get('global');

    // --- Pull phase ---
    final pullResult = await _api.pullDeltas(lastSyncTimestamp);
    lastSyncTimestamp = pullResult.serverTimestamp;
    if (lastSyncTimestamp != null) {
      await _syncMetaDao.set('global', lastSyncTimestamp!);
    }

    // --- Pull phase: Global Risks ---
    final globalRisks = await _api.pullGlobalRisks(lastSyncTimestamp);
    for (final json in globalRisks) {
      await _globalRiskDao.upsertRisk(
        CachedGlobalRisksCompanion.insert(
          id: json['id'] as String,
          label: json['label'] as String,
          description: Value(json['description'] as String?),
          isActive: Value(json['isActive'] as bool? ?? true),
          createdAt: DateTime.parse(json['createdAt'] as String),
          updatedAt: DateTime.parse(json['updatedAt'] as String),
        ),
      );
    }
  }

  Future<void> _drainSubmissions() async {
    // --- Push phase: build payload from normalized DAO tables (FIFO) ---
    final eligibleRows = await _outboxDao.getEligiblePending();
    for (final dbRow in eligibleRows) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      try {
        final answers = await _outboxDao.getAnswersForSubmission(dbRow.id);
        final hasGlobalRisk = await _submissionRiskOutboxDao.hasPendingRisks(
          dbRow.id,
        );

        final payload = jsonEncode({
          'id': dbRow.id,
          'templateId': dbRow.templateId,
          'storeId': dbRow.storeId,
          'clientScore': dbRow.clientScore,
          'sectionScores': dbRow.sectionScores,
          'notes': dbRow.notes,
          'gpsLat': dbRow.gpsLat,
          'gpsLng': dbRow.gpsLng,
          'status': 'completed',
          'idempotencyKey': dbRow.idempotencyKey,
          'targetSubmissionId': dbRow.targetSubmissionId,
          'hasGlobalRisk': hasGlobalRisk,
          'answers': answers.map(SyncEngine.buildAnswerPayload).toList(),
        });

        final entry = PendingSubmission(
          idempotencyKey: dbRow.idempotencyKey,
          createdAt: dbRow.createdAt,
          payload: payload,
        );

        await _api.pushSubmission(entry);
        await _outboxDao.removeSubmission(dbRow.id);
      } catch (e) {
        final isBadRequest =
            e.toString().contains('400') ||
            e.toString().contains('ClientFormatError');

        if (isBadRequest) {
          await _outboxDao.updateSyncStatus(
            dbRow.id,
            'exhausted',
            error: 'FATAL 400: ${e.toString()}',
          );
          continue;
        }

        final isForbidden =
            e.toString().contains('403') ||
            e.toString().toLowerCase().contains('forbidden');

        if (isForbidden) {
          await _outboxDao.updateSyncStatus(
            dbRow.id,
            'exhausted',
            error: 'FATAL 403: Permission denied. Role may have changed.',
          );
          continue;
        }

        final currentRetries = dbRow.retryCount;
        if (currentRetries < _backoffDelays.length) {
          final delaySecs = _backoffDelays[currentRetries];
          final nextRetry = DateTime.now().toUtc().add(
            Duration(seconds: delaySecs),
          );
          await _outboxDao.updateSyncStatus(
            dbRow.id,
            'pending',
            retryCount: currentRetries + 1,
            nextRetryAt: nextRetry,
            error: e.toString(),
          );
          _scheduleRetry(delaySecs);
        } else {
          await _outboxDao.updateSyncStatus(
            dbRow.id,
            'exhausted',
            error: 'Max retries exceeded',
          );
        }
        _state = SyncState.error;
        break; // Stop batch on generic network failure, but allow other phases to run
      }
    }
  }

  Future<void> _drainActionPlans() async {
    // --- Action Plan Evidence Drain phase ---
    final pendingEvidence = await _actionPlanOutboxDao.getEligiblePending();
    for (final entry in pendingEvidence) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }
      try {
        final submissionId = await _actionPlanOutboxDao
            .getSubmissionIdForPlan(entry.actionPlanId);
        String? photoUrl;
        if (entry.photoPath != null && submissionId != null) {
          photoUrl = await _actionPlanApi.uploadPhoto(
            submissionId,
            entry.photoPath!,
          );
        }
        await _actionPlanApi.updateActionPlan(entry.actionPlanId, {
          'status': 'pending_verify',
          'correctionPlan': entry.correctionPlan,
          'evidenceNote': entry.evidenceNote,
          'evidencePhotoUrl': photoUrl,
        });
        await _actionPlanOutboxDao.remove(entry.id);
      } on ActionPlanAlreadyClosedException {
        await _actionPlanOutboxDao.markStaleConflict(entry.id);
      } catch (e) {
        await _actionPlanOutboxDao.markExhausted(entry.id, e.toString());
        _state = SyncState.error;
        break;
      }
    }
  }

  Future<void> _drainRisks() async {
    // --- SubmissionRisk outbox drain phase ---
    final pendingRisks = await _submissionRiskOutboxDao.getEligiblePending();
    for (final row in pendingRisks) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }
      try {
        await _api.pushSubmissionRisk(
          PendingSubmissionRisk(
            submissionId: row.submissionId,
            globalRiskId: row.globalRiskId,
          ),
        );
        await _submissionRiskOutboxDao.remove(row.id);
      } catch (e) {
        if (!e.toString().contains('409')) {
          _state = SyncState.error;
          final currentRetries = row.retryCount;
          if (currentRetries < _backoffDelays.length) {
            final delaySecs = _backoffDelays[currentRetries];
            final nextRetry = DateTime.now().toUtc().add(
              Duration(seconds: delaySecs),
            );
            await _submissionRiskOutboxDao.updateRetry(
              row.id,
              currentRetries + 1,
              nextRetry,
              e.toString(),
            );
            _scheduleRetry(delaySecs);
          } else {
            await _submissionRiskOutboxDao.markExhausted(
              row.id,
              'Max retries exceeded',
            );
          }
          break;
        } else {
          // 409 Conflict = already triggered on server. Treat as success → drain.
          await _submissionRiskOutboxDao.remove(row.id);
        }
      }
    }
  }

  // ── Programs Module Drain Methods (Slice 2B) ─────────────────────────────

  /// Pull phase: fetch all SM assignments from server and full-replace cache.
  Future<void> _pullProgramAssignments() async {
    final assignments = await _api.pullProgramAssignments();

    // Full-replace: delete all cached rows, then reinsert fresh from server.
    await _programOutboxDao.deleteAllCachedAssignments();

    for (final json in assignments) {
      await _programOutboxDao.upsertCachedAssignment(
        CachedProgramAssignmentsCompanion.insert(
          id: json['id'] as String,
          programId: json['programId'] as String,
          programTitle: json['programTitle'] as String,
          category: json['category'] as String,
          deadline: DateTime.parse(json['deadline'] as String),
          status: Value(json['status'] as String? ?? 'pending'),
          rejectionComment: Value(json['rejectionComment'] as String?),
          createdAt: DateTime.parse(json['createdAt'] as String),
        ),
      );
    }

    await _syncMetaDao.set('program_assignments', DateTime.now().toUtc());
  }

  /// Drain phase: push pending evidence submissions from outbox to server.
  Future<void> _drainProgramEvidence() async {
    final pending = await _programOutboxDao.getEligiblePending();
    for (final row in pending) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }
      try {
        final evidenceItems = jsonDecode(row.evidenceItemsJson) as List<dynamic>;
        await _api.pushProgramEvidence(
          row.assignmentId,
          evidenceItems.cast<Map<String, dynamic>>(),
        );
        await _programOutboxDao.remove(row.id);

        // Update local cache: mark assignment as submitted
        await _programOutboxDao.upsertCachedAssignment(
          CachedProgramAssignmentsCompanion(
            id: Value(row.assignmentId),
            status: const Value('submitted'),
          ),
        );
      } catch (e) {
        final isFatal =
            e.toString().contains('400') ||
            e.toString().contains('403') ||
            e.toString().contains('404');

        if (isFatal) {
          await _programOutboxDao.markExhausted(
            row.id,
            'FATAL: ${e.toString()}',
          );
          continue;
        }

        final currentRetries = row.retryCount;
        if (currentRetries < _backoffDelays.length) {
          final delaySecs = _backoffDelays[currentRetries];
          final nextRetry = DateTime.now().toUtc().add(
            Duration(seconds: delaySecs),
          );
          await _programOutboxDao.updateRetry(
            row.id,
            currentRetries + 1,
            nextRetry,
            e.toString(),
          );
          _scheduleRetry(delaySecs);
        } else {
          await _programOutboxDao.markExhausted(row.id, 'Max retries exceeded');
        }
        _state = SyncState.error;
        break;
      }
    }
  }

  /// Drain phase: upload pending program evidence photos.
  Future<void> _drainProgramPhotos() async {
    final pendingPhotos = await _programOutboxDao.getPendingPhotos();
    for (final photo in pendingPhotos) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }
      try {
        await _api.pushProgramPhoto(photo.id, photo.localPath);
        await _programOutboxDao.removePhoto(photo.id);
      } catch (e) {
        final isFatal =
            e.toString().contains('400') ||
            e.toString().contains('403') ||
            e.toString().contains('404') ||
            e.toString().contains('415');

        if (isFatal) {
          await _programOutboxDao.markPhotoExhausted(
            photo.id,
            'FATAL: ${e.toString()}',
          );
          continue;
        }

        final currentRetries = photo.retryCount;
        if (currentRetries < _backoffDelays.length) {
          final delaySecs = _backoffDelays[currentRetries];
          final nextRetry = DateTime.now().toUtc().add(
            Duration(seconds: delaySecs),
          );
          await _programOutboxDao.updatePhotoRetry(
            photo.id,
            currentRetries + 1,
            nextRetry,
            e.toString(),
          );
          _scheduleRetry(delaySecs);
        } else {
          await _programOutboxDao.markPhotoExhausted(photo.id, 'Max retries exceeded');
        }
        _state = SyncState.error;
        break;
      }
    }
  }
}
