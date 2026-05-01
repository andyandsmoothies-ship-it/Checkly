import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:meta/meta.dart';

import 'package:checkly/_shared/database/dao/outbox_dao.dart';
import 'package:checkly/_shared/database/dao/action_plan_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/global_risk_dao.dart';
import 'package:checkly/_shared/database/dao/submission_risk_outbox_dao.dart';
import 'package:checkly/_shared/database/dao/sync_meta_dao.dart';
import 'package:checkly/_shared/database/dao/program_outbox_dao.dart';
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

part 'sync_engine_drains.dart';

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
  final ProgramOutboxDao _programOutboxDao;

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
    required ProgramOutboxDao programOutboxDao,
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
       _syncMetaDao = syncMetaDao,
       _programOutboxDao = programOutboxDao {
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
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      // Programs Module Slice 2B: SM assignment pull + evidence push
      await _pullProgramAssignments();
      if (!_connectivity.isOnline) {
        _state = SyncState.offline;
        return;
      }

      await _drainProgramEvidence();
      await _drainProgramPhotos();

      if (_state == SyncState.syncing) {
        _state = SyncState.idle;
      }
    } catch (_) {
      _state = SyncState.error;
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
