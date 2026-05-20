import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'sync_state.dart';
import 'sync_module.dart';
import 'auth_check.dart';
import '../database/dao/outbox_dao.dart';
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
  final OutboxDao? _outboxDao;

  /// SA-4: Max jitter in milliseconds added before reconnect-triggered sync.
  /// Set to 0 in tests so sync fires immediately without needing a long delay.
  final int _maxReconnectJitterMs;

  StreamSubscription<bool>? _connectivitySub;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;
  Timer? _retryTimer;

  SyncEngine({
    required ConnectivityService connectivity,
    required AuthCheck auth,
    required List<SyncModule> modules,
    OutboxDao? outboxDao,
    int maxReconnectJitterMs = 10000,
  }) : _connectivity = connectivity,
       _auth = auth,
       _outboxDao = outboxDao,
       _maxReconnectJitterMs = maxReconnectJitterMs,
       _modules = List.unmodifiable(
         [...modules]..sort((a, b) => a.priority.compareTo(b.priority)),
       ) {
    // Initialize state based on current connectivity
    if (!_connectivity.isOnline) {
      _state = SyncState.offline;
    }

    // Listen to connectivity changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (isOnline) {
        if (isOnline) {
          // Going online → trigger sync.
          // SA-4: Add jitter (0–maxReconnectJitterMs) to prevent thundering herd
          // when many devices reconnect simultaneously. Tests inject 0 to disable.
          _state = SyncState.idle;
          final jitterMs = _maxReconnectJitterMs > 0
              ? Random().nextInt(_maxReconnectJitterMs)
              : 0;
          Future.delayed(Duration(milliseconds: jitterMs), requestSync);
        } else {
          // Going offline → set state immediately
          _state = SyncState.offline;
        }
      },
      onError: (Object error) {
        // SA-2: The stream emitted a platform error (OS/plugin exception).
        // The subscription stays alive after onError (cancelOnError defaults to false).
        // Log and continue — the subscription may recover on its own.
        // ignore: avoid_print
        debugPrint('[SyncEngine] connectivity stream error: $error');
      },
      onDone: () {
        // SA-2: The stream closed permanently (plugin restart, OS battery kill).
        // Without a fallback, the engine never sees another connectivity event.
        // Activate a periodic poll so the engine is not frozen indefinitely.
        // ignore: avoid_print
        debugPrint(
          '[SyncEngine] connectivity stream closed. Activating poll fallback.',
        );
        _startConnectivityPollFallback();
      },
    );

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

  // ── Outbox monitoring proxy ─────────────────────────────────────────────
  // UI widgets must NOT import OutboxDao directly. Route all outbox queries
  // through SyncEngine to keep the architecture boundary clean.

  /// Emits the count of exhausted outbox items (triggers UX Red Badge).
  Stream<int> watchExhaustedCount() => _outboxDao!.watchExhaustedCount();

  /// Permanently discards all exhausted outbox items.
  Future<void> discardExhausted() => _outboxDao!.discardExhausted();

  /// Resets all exhausted outbox items back to 'pending' for retry.
  Future<void> requeueExhausted() => _outboxDao!.requeueExhausted();

  /// Returns the count of items eligible for sync (pending, not exhausted).
  Future<int> syncableCount() => _outboxDao!.syncableCount();

  /// Returns the count of exhausted items.
  Future<int> exhaustedCount() => _outboxDao!.exhaustedCount();

  // SA-2: Fallback poll when the connectivity stream closes permanently.
  // Fires every 30 seconds and re-checks connectivity via the cached native value.
  // Low-cost: no network I/O, just reads a native boolean from ConnectivityService.
  void _startConnectivityPollFallback() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final isOnline = _connectivity.isOnline;
      if (isOnline && _state != SyncState.syncing) {
        _state = SyncState.idle;
        requestSync();
      }
    });
  }

  /// Dispose the connectivity listener.
  void dispose() {
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
