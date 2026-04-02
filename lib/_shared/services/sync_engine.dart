import 'dart:async';

import 'package:checkly/_shared/database/dao/outbox_dao.dart';
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
  final Outbox _outbox;
  final AuthCheck _auth;
  final OutboxDao _outboxDao; // Direct DAO access for backoff writes

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
  }) : _connectivity = connectivity,
       _api = api,
       _outbox = outbox,
       _auth = auth,
       _outboxDao = outboxDao {
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

      // --- Push phase: use Outbox interface entries (carry payload) ---
      // Filter to only eligible entries using the backoff-gated DAO query.
      // The eligible set is keyed by idempotencyKey for O(1) cross-reference.
      final eligibleRows = await _outboxDao.getEligiblePending();
      final eligibleKeys = {for (final r in eligibleRows) r.idempotencyKey: r};

      final sortedPending = List<PendingSubmission>.from(_outbox.pending)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final entry in sortedPending) {
        // Skip if not in the backoff-eligible set
        final dbEntry = eligibleKeys[entry.idempotencyKey];
        if (dbEntry == null) continue;

        // Check connectivity before each push
        if (!_connectivity.isOnline) {
          _state = SyncState.offline;
          return;
        }

        try {
          await _api.pushSubmission(entry);
          await _outbox.remove(entry.idempotencyKey);
        } catch (e) {
          // Apply SQLite-backed exponential backoff (Pillar D).
          // No Timer spawned — backoff is evaluated at query-time via nextRetryAt.
          final currentRetries = dbEntry.retryCount;
          if (currentRetries < _backoffDelays.length) {
            final delaySecs = _backoffDelays[currentRetries];
            final nextRetry = DateTime.now().toUtc().add(
              Duration(seconds: delaySecs),
            );
            await _outboxDao.updateSyncStatus(
              dbEntry.id,
              'pending',
              retryCount: currentRetries + 1,
              nextRetryAt: nextRetry,
              error: e.toString(),
            );
          } else {
            // Exhausted — UX Red Badge will appear via watchExhaustedCount()
            await _outboxDao.updateSyncStatus(
              dbEntry.id,
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
