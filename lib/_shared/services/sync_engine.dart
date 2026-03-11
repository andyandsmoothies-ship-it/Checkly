import 'dart:async';

import 'connectivity_service.dart';
import 'sync_state.dart';

// ============================================================
// Models
// ============================================================

/// A pending submission queued in the local outbox.
class PendingSubmission {
  final String idempotencyKey;
  final DateTime createdAt;
  final String payload;

  const PendingSubmission({
    required this.idempotencyKey,
    required this.createdAt,
    required this.payload,
  });
}

/// Result of a delta pull — carries the server's latest timestamp.
class DeltaPullResult {
  final DateTime serverTimestamp;

  const DeltaPullResult({required this.serverTimestamp});
}

// ============================================================
// Interfaces
// ============================================================

/// Abstract API for sync operations.
abstract class SyncApi {
  /// Push a single pending submission to the server.
  Future<void> pushSubmission(PendingSubmission submission);

  /// Pull delta updates from server since [since].
  Future<DeltaPullResult> pullDeltas(DateTime? since);
}

/// Abstract outbox for pending submissions.
abstract class Outbox {
  /// All pending entries (snapshot).
  List<PendingSubmission> get pending;

  /// Add an entry to the outbox.
  Future<void> add(PendingSubmission entry);

  /// Remove an entry by its idempotency key.
  Future<void> remove(String idempotencyKey);
}

/// Abstract auth check for sync gating.
abstract class AuthCheck {
  /// Whether the user is currently logged in with a valid session.
  bool get isLoggedIn;
}

// ============================================================
// SyncEngine — orchestrator
// ============================================================

/// Orchestrates data sync between local Drift DB and remote API.
///
/// Rules:
/// 1. Listens to connectivity. Online → sync. Offline → state=offline.
/// 2. No concurrent sync — if already syncing, new requests are ignored.
/// 3. Auth gate — if not logged in, sync is skipped.
/// 4. Pull phase first (delta updates), then push phase (FIFO outbox drain).
/// 5. Push is sequential, FIFO by createdAt ascending.
/// 6. Partial push failure → stop, keep remaining, state=error.
/// 7. On connectivity loss → state=offline.
class SyncEngine {
  final ConnectivityService _connectivity;
  final SyncApi _api;
  final Outbox _outbox;
  final AuthCheck _auth;

  StreamSubscription<bool>? _connectivitySub;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;

  DateTime? lastSyncTimestamp;

  SyncEngine({
    required ConnectivityService connectivity,
    required SyncApi api,
    required Outbox outbox,
    required AuthCheck auth,
  }) : _connectivity = connectivity,
       _api = api,
       _outbox = outbox,
       _auth = auth {
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

      // --- Push phase (FIFO) ---
      final sortedPending = List<PendingSubmission>.from(_outbox.pending)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (final entry in sortedPending) {
        // Check connectivity before each push
        if (!_connectivity.isOnline) {
          _state = SyncState.offline;
          return;
        }

        try {
          await _api.pushSubmission(entry);
          await _outbox.remove(entry.idempotencyKey);
        } catch (_) {
          // Push failed — stop processing, keep remaining entries
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
