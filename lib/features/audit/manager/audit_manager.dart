import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/dao/global_risk_dao.dart';
import '../../../_shared/database/dao/submission_risk_outbox_dao.dart';
import '../../../_shared/database/dao/outbox_dao.dart'; // Kept as it's used
import '../../../_shared/services/connectivity_service.dart'; // Kept as it's used
import '../../../_shared/services/scoring_engine.dart'; // Kept as it's used
import '../../../_shared/services/scoring_mode.dart';
import '../../../_shared/services/section_score.dart';
import '../../../_shared/services/sync_engine.dart';
import '../../auth/manager/auth_manager.dart';
import '../../templates/models/template_dto.dart';
import '../model/audit_answer.dart';
export '../model/audit_answer.dart';
import '../model/submission_dto.dart';
import '../services/draft_service.dart'; // Added
import '../services/scoring_input_mapper.dart';
import '../services/submission_api_service.dart';

part 'audit_manager_draft.dart';
part 'audit_manager_submit.dart';

final _di = GetIt.instance;
const _uuid = Uuid();

/// PFA Manager for the audit form — offline-first write path.
///
/// `submitAudit()`:
/// 1. Generate idempotency key
/// 2. Save to Drift outbox (pending_submissions + pending_answers)
/// 3. If online: trigger sync. If offline: queued for later.
class AuditManager extends ChangeNotifier {
  // ignore: unused_field — kept as injectable test seam; SpySubmissionApiService verifies HTTP path is never reached.
  final SubmissionApiService _api;
  final OutboxDao _outbox;
  final GlobalRiskDao _globalRiskDao;
  final SubmissionRiskOutboxDao _riskOutboxDao;
  final ConnectivityService? _connectivity;

  AuditManager({
    required SubmissionApiService api,
    required OutboxDao outbox,
    required GlobalRiskDao globalRiskDao,
    required SubmissionRiskOutboxDao riskOutboxDao,
    required DraftService draftService,
    ConnectivityService? connectivity,
  })  : _api = api,
        _outbox = outbox,
        _globalRiskDao = globalRiskDao,
        _riskOutboxDao = riskOutboxDao,
        _connectivity = connectivity {
    _draftService = draftService;
  }

  // ---------- State ----------
  TemplateTreeDto? _template;
  TemplateTreeDto? get template => _template;

  String? _pendingSubmissionId;

  List<CachedGlobalRisk> _availableRisks = [];
  List<CachedGlobalRisk> get availableRisks => _availableRisks;

  final Set<String> _triggeredRiskIds = {};
  Set<String> get triggeredRiskIds => Set.unmodifiable(_triggeredRiskIds);

  /// Current scoring mode parsed from the active template, defaults to penalty.
  ScoringMode get scoringMode {
    if (_template == null) return ScoringMode.penalty;
    return ScoringInputMapper.parseScoringMode(_template!.scoringLogicConfig);
  }

  String? _storeId;
  String? get storeId => _storeId;

  final Map<String, AuditAnswer> _answers = {};
  Map<String, AuditAnswer> get answers => Map.unmodifiable(_answers);

  double? _liveScore = 100.0;
  double? get liveScore => _liveScore;

  Map<String, SectionScore> _sectionScores = {};
  Map<String, SectionScore> get sectionScores => _sectionScores;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  SubmissionDto? _lastSubmission;
  SubmissionDto? get lastSubmission => _lastSubmission;

  String? _notes;
  String? get notes => _notes;

  double? _gpsLat;
  double? _gpsLng;

  /// Whether the last submit was queued offline (not sent to API).
  bool _wasQueuedOffline = false;
  bool get wasQueuedOffline => _wasQueuedOffline;

  // ---------- Draft State ----------
  late final DraftService _draftService;
  String? _draftKey;
  DraftData? _pendingDraft;
  DateTime? _draftSavedAt;

  /// True if a draft was found for this template+store+user combo.
  bool get hasDraft => _pendingDraft != null;

  /// Draft data to restore (set after startAudit if draft exists).
  DraftData? get pendingDraft => _pendingDraft;

  /// Last draft save timestamp (for UI indicator).
  DateTime? get draftSavedAt => _draftSavedAt;

  // ---------- Resume Resume State ----------
  /// When non-null, this audit is finalizing an EXISTING server-side draft.
  /// SyncEngine reads this from the outbox row to route PUT instead of POST.
  String? _targetSubmissionId;

  // ---------- Init ----------
  Future<void> startAudit(
    TemplateTreeDto template,
    String storeId, {
    String? targetSubmissionId,
  }) async {
    _template = template;
    _storeId = storeId;
    _answers.clear();
    _liveScore = 100.0;
    _error = null;
    _lastSubmission = null;
    _notes = null;
    _gpsLat = null;
    _gpsLng = null;
    _wasQueuedOffline = false;
    _draftSavedAt = null;
    _targetSubmissionId = targetSubmissionId;
    _pendingSubmissionId = _uuid.v4(); // Stable ID for this local session
    _triggeredRiskIds.clear();

    // Pre-populate answers for all criteria
    for (final group in template.groups) {
      _initGroupAnswers(group);
    }

    // Compute draft key
    String? userId;
    try {
      userId = _di<AuthManager>().currentUser?.userId;
    } catch (_) {}
    _draftKey = '${template.id}:$storeId:${userId ?? 'anon'}';

    // Check for existing draft
    _pendingDraft = await _draftService.loadDraft(_draftKey!);

    _availableRisks = await _globalRiskDao.getActiveRisks();

    if (_pendingDraft == null) {
      _scheduleDraftSave();
      // For scheduled audits (targetSubmissionId != null), the local SQLite draft
      // is never written until the first answer is saved (3s debounce). If the auditor
      // navigates away before answering, hasDraft stays false and resume opens a blank
      // form. Flush an empty stub immediately so hasDraft = true on next open.
      if (_targetSubmissionId != null) {
        final answersMap = _answers.map((k, v) => MapEntry(k, v.toJson()));
        await _draftService.flushSave(
          draftKey: _draftKey!,
          answersMap: answersMap,
          notes: _notes,
        );
        _pendingDraft = await _draftService.loadDraft(_draftKey!);
      }
    }

    _recalculateScore();
    notifyListeners();
  }

  void _initGroupAnswers(GroupDto group) {
    for (final criterion in group.criteria) {
      _answers[criterion.id] = AuditAnswer(
        criteriaId: criterion.id,
        isCcp: false,
        isRisk: false,
      );
    }
    for (final child in group.children) {
      _initGroupAnswers(child);
    }
  }

  // ---------- Answer updates ----------
  void setAnswer(String criteriaId, {String? value, double? numericValue}) {
    final answer = _answers[criteriaId];
    if (answer == null) return;

    if (value != null) answer.value = value;
    if (numericValue != null) answer.numericValue = numericValue;

    _recalculateScore();
    _scheduleDraftSave();
    notifyListeners();
  }

  void clearAnswerValue(String criteriaId) {
    if (_answers[criteriaId] != null) {
      _answers[criteriaId]!.value = null;
      _recalculateScore();
      _scheduleDraftSave();
      notifyListeners();
    }
  }

  void setNote(String criteriaId, String note) {
    _answers[criteriaId]?.note = note;
    _scheduleDraftSave();
    notifyListeners();
  }

  void setRepeatedError(String criteriaId, bool value) {
    _answers[criteriaId]?.repeatedFaultCount = value ? 1 : 0;
    _scheduleDraftSave();
    notifyListeners();
  }

  void setRepeatedFaultCount(String criteriaId, int count) {
    final a = _answers[criteriaId];
    if (a != null) {
      a.repeatedFaultCount = count < 0 ? 0 : count;
      _scheduleDraftSave();
      notifyListeners();
    }
  }

  void setPhotoUrl(String criteriaId, String? url) {
    _answers[criteriaId]?.photoUrl = url;
    _scheduleDraftSave();
    notifyListeners();
  }

  void setCcp(String criteriaId, bool value) {
    _answers[criteriaId]?.isCcp = value;
    _recalculateScore();
    _scheduleDraftSave();
    notifyListeners();
  }

  void setRisk(String criteriaId, bool value) {
    _answers[criteriaId]?.isRisk = value;
    _recalculateScore();
    _scheduleDraftSave();
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    _scheduleDraftSave();
    notifyListeners();
  }

  void setGps(double lat, double lng) {
    _gpsLat = lat;
    _gpsLng = lng;
  }

  // ---------- Live scoring ----------
  void _recalculateScore() {
    if (_template == null) return;
    final input = ScoringInputMapper.fromTemplate(
      _template!,
      _answers,
      hasGlobalRisk: _triggeredRiskIds.isNotEmpty,
    );
    final result = ScoringEngine.calculate(input);
    _liveScore = result.totalScore;
    _sectionScores = result.sectionScores;
  }

  // ---------- Section scores JSON ----------
  // Reads from _sectionScores computed by _recalculateScore() — no re-calculation.
  String _buildSectionScoresJson() {
    if (_template == null) return '{}';
    final sections = <String, dynamic>{};
    for (final group in _template!.groups) {
      sections[group.id] = {
        'title': group.title,
        'weight': group.weight,
        'maxPoints': _sectionScores[group.id]?.maxPoints ?? 0.0,
      };
    }
    return jsonEncode(sections);
  }

  // ---------- Global Risk Actions ----------

  Future<void> triggerGlobalRisk(String globalRiskId) async {
    if (_pendingSubmissionId == null) return;

    _triggeredRiskIds.add(globalRiskId);
    await _riskOutboxDao.enqueueRisk(_pendingSubmissionId!, globalRiskId);

    _recalculateScore();
    notifyListeners();
  }

  Future<void> unTriggerGlobalRisk(String globalRiskId) async {
    if (_pendingSubmissionId == null) return;

    _triggeredRiskIds.remove(globalRiskId);
    await _riskOutboxDao.removeByRiskId(_pendingSubmissionId!, globalRiskId);

    _recalculateScore();
    notifyListeners();
  }

  // ---------- Pending count (syncable-only — excludes exhausted) ----------
  Future<int> get pendingCount => _outbox.syncableCount();

  // ---------- Submit API ----------
  Future<void> submitAudit() => _submitAuditLogic(this);

  // ---------- Draft API ----------
  void _scheduleDraftSave() => _scheduleDraftSaveLogic(this);
  Future<void> forceSave() => _forceSaveLogic(this);
  void restoreDraft() => _restoreDraftLogic(this);
  void discardDraft() => _discardDraftLogic(this);

  // ---------- Reset ----------
  void reset() {
    _draftService.dispose();
    _template = null;
    _storeId = null;
    _answers.clear();
    _liveScore = 100.0;
    _error = null;
    _lastSubmission = null;
    _notes = null;
    _gpsLat = null;
    _gpsLng = null;
    _wasQueuedOffline = false;
    _draftKey = null;
    _pendingDraft = null;
    _draftSavedAt = null;
    _targetSubmissionId = null;
    _pendingSubmissionId = null;
    _triggeredRiskIds.clear();
    _availableRisks = [];
    notifyListeners();
  }
}
