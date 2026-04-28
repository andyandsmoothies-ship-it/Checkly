import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:meta/meta.dart';

import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/sync_meta_dao.dart';
import 'package:checkly/_shared/database/app_database.dart'
    hide PendingSubmission;
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'connectivity_service.dart';
import 'sync_state.dart';
import 'pending_submission.dart';
import 'pending_submission_risk.dart';
import 'sync_api.dart';
import 'outbox.dart';
import 'auth_check.dart';

// ============================================================
// SyncEngine — orchestrator
// ============================================================

/// Backoff delay sequence in seconds: 1st, 2nd, 3rd, 4th failure.
const List<int> _backoffDelays = [2, 4, 8, 60];

/// Orchestrates data sync between local Drift DB and remote API.
///
/// Rules:
/// 1. Listens to connectivity. Online → sync. Offline → state=offline.
/// 2. No concurrent sync — if already syncing, new requests are ignored.
/// 3. Auth gate — if not logged in, sync is skipped.
/// 4. Pull phase first (delta updates), then push phase (FIFO outbox drain).
/// 5. Push is sequential, FIFO by createdAt ascending.
/// 6. On network failure: applies SQLite-persisted exponential backoff.
///    After 4 failures, status → `exhausted` (triggers UX Red Badge).
/// 7. On connectivity loss → state=offline.
class SyncEngine {
  final ConnectivityService _connectivity;
  final SyncApi _api;

  final AuthCheck _auth;
  final OutboxDao _outboxDao; // Direct DAO access for backoff writes
  final ActionPlanApi _actionPlanApi; // For draining offline evidence queue
  final ActionPlanOutboxDao _actionPlanOutboxDao;
  final GlobalRiskDao _globalRiskDao;
  final SubmissionRiskOutboxDao _submissionRiskOutboxDao;
  final SyncMetaDao _syncMetaDao;

  StreamSubscription<bool>? _connectivitySub;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  DateTime? lastSyncTimestamp;
  Timer? _retryTimer;

  SyncEngine({
    required ConnectivityService connectivity,
    required SyncApi api,

    required AuthCheck auth,
    required OutboxDao outboxDao,
    required ActionPlanApi actionPlanApi,
    required ActionPlanOutboxDao actionPlanOutboxDao,
    required GlobalRiskDao globalRiskDao,
    required SubmissionRiskOutboxDao submissionRiskOutboxDao,
    required SyncMetaDao syncMetaDao,
    // ignore: avoid_unused_constructor_parameters
    @Deprecated(
      'No-op: SyncEngine uses OutboxDao directly. Pass outboxDao instead.',
    )
    Outbox? outbox,
  }) : _connectivity = connectivity,
       _api = api,
       _auth = auth,
       _outboxDao = outboxDao,
       _actionPlanApi = actionPlanApi,
       _actionPlanOutboxDao = actionPlanOutboxDao,
       _globalRiskDao = globalRiskDao,
       _submissionRiskOutboxDao = submissionRiskOutboxDao,
       _syncMetaDao = syncMetaDao {
    // Initialize state based on current connectivity
    if (!_connectivity.isOnline) {
      _state = SyncState.offline;
    }

    // Listen to connectivity changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        // Going online → trigger sync
        _state = SyncState.idle;
        requestSync();
      } else {
        // Going offline → set state immediately
        _state = SyncState.offline;
      }
    });

    // Initial sync is driven by the App widget or explicit calls, not the constructor.
  }

  /// Returns the counts of syncable and exhausted submissions in the outbox.
  Future<(int syncable, int exhausted)> getPendingCount() async {
    final syncable = await _outboxDao.syncableCount();
    final exhausted = await _outboxDao.exhaustedCount();
    return (syncable, exhausted);
  }

  /// Request a sync cycle. If already syncing, the request is ignored.
  Future<void> requestSync() async {
    _retryTimer?.cancel(); // Cancel any pending retry

    // Guard: no concurrent sync
    if (_state == SyncState.syncing) return;

    // Guard: skip if offline
    if (!_connectivity.isOnline) {
      _state = SyncState.offline;
      return;
    }

    // Guard: skip if not authenticated
    if (!_auth.isLoggedIn) {
      // State stays idle — not an error, just not ready
      return;
    }

    _state = SyncState.syncing;

    try {
      await _pullDeltas();
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await _drainSubmissions();
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await _drainActionPlans();
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await _drainRisks();

      if (_state == SyncState.syncing) {
        _state = SyncState.idle;
      }
    } catch (_) {
      _state = SyncState.error;
    }
  }

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
          'answers': answers.map(buildAnswerPayload).toList(),
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
          'evidencePhotoUrl': photoUrl, // Fixed missing ?
        });
        await _actionPlanOutboxDao.remove(entry.id);
      } on ActionPlanAlreadyClosedException {
        await _actionPlanOutboxDao.markStaleConflict(entry.id);
      } catch (e) {
        await _actionPlanOutboxDao.markExhausted(entry.id, e.toString());
        _state = SyncState.error;
        break; // Fixed from return; to break;
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
          // Apply Backoff logic from Slice 2
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
          break; // Stop batch on generic network failure
        } else {
          // 409 Conflict = already triggered on server. Treat as success → drain.
          await _submissionRiskOutboxDao.remove(row.id);
        }
      }
    }
  }

  /// Dispose the connectivity listener.
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  void _scheduleRetry(int delaySecs) {
    if (_retryTimer?.isActive == true) return; // Keep existing sooner timer
    _retryTimer = Timer(Duration(seconds: delaySecs), () {
      requestSync();
    });
  }

  @visibleForTesting
  static Map<String, dynamic> buildAnswerPayload(dynamic a) {
    return {
      'criteriaId': a.criteriaId,
      'value': a.value,
      'numericValue': a.numericValue,
      'note': a.note,
      'photoUrl': a.photoUrl,
      'isRepeatedError': a.isRepeatedError,
      'repeatedFaults': a.repeatedFaults,
      'isCcp': a
          .isCcp, // Fix: was silently dropped — server override merge requires this
      'isRisk': a
          .isRisk, // Fix: was silently dropped — RISK flag triggers total=0 on server
    };
  }
}
