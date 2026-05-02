import 'dart:async';

import 'connectivity_service.dart';
import 'sync_state.dart';
import 'sync_module.dart';
import 'auth_check.dart';
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
/// 6. On network failure: applies SQLite-persisted exponential backoff.
///    After 4 failures, status → `exhausted` (triggers UX Red Badge).
/// 7. On connectivity loss → state=offline.
class SyncEngine {
  final ConnectivityService _connectivity;
  final AuthCheck _auth;
  final List<SyncModule> _modules;

  StreamSubscription<bool>? _connectivitySub;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;
  Timer? _retryTimer;

  SyncEngine({
    required ConnectivityService connectivity,
    required AuthCheck auth,
    required List<SyncModule> modules,
  }) : _connectivity = connectivity,
       _auth = auth,
       _modules = List.unmodifiable(
         [...modules]..sort((a, b) => a.priority.compareTo(b.priority)),
       ) {
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

  Future<void>? _activeSync;

  /// Request a sync cycle. If already syncing, returns the active sync future.
  Future<void> requestSync() {
    _retryTimer?.cancel(); // Cancel any pending retry

    if (_activeSync != null) {
      return _activeSync!;
    }

    _activeSync = _requestSyncInternal().whenComplete(() {
      _activeSync = null;
    });

    return _activeSync!;
  }

  Future<void> _requestSyncInternal() async {
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
      await _runModuleSyncCycle();

      if (_state == SyncState.syncing) {
        _state = SyncState.idle;
      }
    } catch (_) {
      _state = SyncState.error;
    }
  }

  Future<void> _runModuleSyncCycle() async {
    for (final module in _modules) {
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await module.executePull();

      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await module.executePush();
    }
  }

  /// Dispose the connectivity listener.
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
