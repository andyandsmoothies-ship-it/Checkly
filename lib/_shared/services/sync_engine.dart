import 'dart:async';
import 'dart:convert';

import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/features/action_plans/manager/action_plan_manager.dart';
import 'connectivity_service.dart';
import 'sync_state.dart';
import 'sync_interfaces.dart';

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
  // ignore: unused_field — Outbox interface kept as constructor seam; _outboxDao used directly for removal (TODO: cleanup in follow-up PR).
  final Outbox _outbox;
  final AuthCheck _auth;
  final OutboxDao _outboxDao; // Direct DAO access for backoff writes
  final ActionPlanApi _actionPlanApi; // For draining offline evidence queue
  final ActionPlanOutboxDao _actionPlanOutboxDao;

  StreamSubscription<bool>? _connectivitySub;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  DateTime? lastSyncTimestamp;

  SyncEngine({
    required ConnectivityService connectivity,
    required SyncApi api,
    required Outbox outbox,
    required AuthCheck auth,
    required OutboxDao outboxDao,
    required ActionPlanApi actionPlanApi,
    required ActionPlanOutboxDao actionPlanOutboxDao,
  }) : _connectivity = connectivity,
       _api = api,
       _outbox = outbox,
       _auth = auth,
       _outboxDao = outboxDao,
       _actionPlanApi = actionPlanApi,
       _actionPlanOutboxDao = actionPlanOutboxDao {
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
  }

  /// Request a sync cycle. If already syncing, the request is ignored.
  Future<void> requestSync() async {
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
      // --- Pull phase ---
      final pullResult = await _api.pullDeltas(lastSyncTimestamp);
      lastSyncTimestamp = pullResult.serverTimestamp;

      // --- Push phase: build payload from normalized DAO tables (FIFO) ---
      // Fetch backoff-eligible entries directly from DAO — ordered by createdAt ASC.
      // _outbox.pending is bypassed because it is synchronous and cannot
      // load rows from SQLite — DAO query is the source of truth.
      final eligibleRows = await _outboxDao.getEligiblePending();
      for (final dbRow in eligibleRows) {
        // Check connectivity before each push
        if (!_connectivity.isOnline) {
          _state = SyncState.offline;
          return;
        }

        try {
          // Fetch answers for this submission from the normalized table
          final answers = await _outboxDao.getAnswersForSubmission(dbRow.id);

          // Build the JSON payload the API expects
          final payload = jsonEncode({
            'templateId': dbRow.templateId,
            'storeId': dbRow.storeId,
            'clientScore': dbRow.clientScore,
            'sectionScores': dbRow.sectionScores,
            'notes': dbRow.notes,
            'gpsLat': dbRow.gpsLat,
            'gpsLng': dbRow.gpsLng,
            'status': 'completed',
            'idempotencyKey': dbRow.idempotencyKey,
            'answers': answers.map((a) => {
              'criteriaId': a.criteriaId,
              'value': a.value,
              'numericValue': a.numericValue,
              'note': a.note,
              'photoUrl': a.photoUrl,
              'isRepeatedError': a.isRepeatedError,
            }).toList(),
          });

          final entry = PendingSubmission(
            idempotencyKey: dbRow.idempotencyKey,
            createdAt: dbRow.createdAt,
            payload: payload,
          );

          await _api.pushSubmission(entry);
          await _outboxDao.removeSubmission(dbRow.id);
        } catch (e) {
          // Hard-exhaust on malformed payload (e.g. 400 Bad Request)
          final isBadRequest = e.toString().contains('400') || e.toString().contains('ClientFormatError');
          
          if (isBadRequest) {
            await _outboxDao.updateSyncStatus(
              dbRow.id,
              'exhausted',
              error: 'FATAL 400: ${e.toString()}',
            );
            continue;
          }

          // Apply SQLite-backed exponential backoff (Pillar D).
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
          } else {
            await _outboxDao.updateSyncStatus(
              dbRow.id,
              'exhausted',
              error: 'Max retries exceeded',
            );
          }
          _state = SyncState.error;
          return;
        }
      }

      // All done — check connectivity one last time
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      // --- Action Plan Evidence Drain phase ---
      // Drain any queued offline evidence submissions (P1 UX Fix).
      final pendingEvidence = await _actionPlanOutboxDao.getEligiblePending();
      for (final entry in pendingEvidence) {
        if (!_connectivity.isOnline) {
          _state = SyncState.offline;
          return;
        }
        try {
          await _actionPlanApi.updateActionPlan(entry.actionPlanId, {
            'status': 'pending_verify',
            'correctionPlan': entry.correctionPlan,
            'evidenceNote': entry.evidenceNote,
          });
          await _actionPlanOutboxDao.remove(entry.id);
        } catch (e) {
          await _actionPlanOutboxDao.markExhausted(
            entry.id,
            e.toString(),
          );
          _state = SyncState.error;
          return;
        }
      }

      _state = SyncState.idle;
    } catch (_) {
      _state = SyncState.error;
    }
  }

  /// Dispose the connectivity listener.
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
