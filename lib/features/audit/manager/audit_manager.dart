import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/app_database.dart';
import '../../../_shared/database/dao/outbox_dao.dart'; // Kept as it's used
import '../../../_shared/services/connectivity_service.dart'; // Kept as it's used
import '../../../_shared/services/scoring_engine.dart'; // Kept as it's used
import '../../auth/manager/auth_manager.dart';
import '../../templates/models/template_dto.dart';
import '../model/submission_dto.dart';
import '../services/draft_service.dart'; // Added
import '../services/scoring_input_mapper.dart';
import '../services/submission_api_service.dart';

final _di = GetIt.instance;
const _uuid = Uuid();

/// In-progress answer entry for the audit form.
class AuditAnswer {
  final String criteriaId;
  String? value; // 'conform', 'non_conform', 'na'
  double? numericValue; // fault count
  String? note;
  String? photoUrl;
  int repeatedFaultCount;
  bool isCcp;
  bool isRisk;

  /// Derived from repeatedFaultCount for backward compatibility.
  bool get isRepeatedError => repeatedFaultCount > 0;

  AuditAnswer({
    required this.criteriaId,
    this.value,
    this.numericValue,
    this.note,
    this.photoUrl,
    this.repeatedFaultCount = 0,
    this.isCcp = false,
    this.isRisk = false,
  });

  /// Serializes to JSON-compatible map for draft storage.
  Map<String, dynamic> toJson() => {
    'criteriaId': criteriaId,
    'value': value,
    'numericValue': numericValue,
    'note': note,
    'photoUrl': photoUrl,
    'repeatedFaultCount': repeatedFaultCount,
    'isCcp': isCcp,
    'isRisk': isRisk,
  };

  /// Restores from a JSON map (from draft storage).
  factory AuditAnswer.fromJson(Map<String, dynamic> json) => AuditAnswer(
    criteriaId: json['criteriaId'] as String,
    value: json['value'] as String?,
    numericValue: (json['numericValue'] as num?)?.toDouble(),
    note: json['note'] as String?,
    photoUrl: json['photoUrl'] as String?,
    repeatedFaultCount: (json['repeatedFaultCount'] as int?) ?? 0,
    isCcp: (json['isCcp'] as bool?) ?? false,
    isRisk: (json['isRisk'] as bool?) ?? false,
  );

  /// Converts to submission API payload.
  SubmissionAnswerInput toInput() => SubmissionAnswerInput(
    criteriaId: criteriaId,
    value: value,
    numericValue: numericValue,
    note: note,
    photoUrl: photoUrl,
    isRepeatedError: isRepeatedError,
  );
}

/// PFA Manager for the audit form — offline-first write path.
///
/// `submitAudit()`:
/// 1. Generate idempotency key
/// 2. Save to Drift outbox (pending_submissions + pending_answers)
/// 3. If online: trigger sync. If offline: queued for later.
class AuditManager extends ChangeNotifier {
  final SubmissionApiService _api;
  late final OutboxDao _outbox;
  late final ConnectivityService? _connectivity;

  AuditManager({
    SubmissionApiService? api,
    OutboxDao? outbox,
    ConnectivityService? connectivity,
    DraftService? draftService,
  }) : _api = api ?? _di<SubmissionApiService>() {
    final db = _di<DatabaseService>().db;
    _outbox = outbox ?? OutboxDao(db);
    _draftService = draftService ?? DraftService();
    try {
      _connectivity = connectivity ?? _di<ConnectivityService>();
    } catch (_) {
      _connectivity = null;
    }
  }

  // ---------- State ----------
  TemplateTreeDto? _template;
  TemplateTreeDto? get template => _template;

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

  // ---------- Init ----------
  Future<void> startAudit(TemplateTreeDto template, String storeId) async {
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
    final input = ScoringInputMapper.fromTemplate(_template!, _answers);
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

  // ---------- Draft helpers ----------

  /// Schedules a debounced draft save.
  void _scheduleDraftSave() {
    if (_draftKey == null) return;
    final answersMap = _answers.map((k, v) => MapEntry(k, v.toJson()));
    _draftService.scheduleSave(
      draftKey: _draftKey!,
      answersMap: answersMap,
      notes: _notes,
    );
    _draftSavedAt = DateTime.now();
  }

  /// Restores answers from a loaded draft.
  void restoreDraft() {
    final draft = _pendingDraft;
    if (draft == null) return;

    for (final entry in draft.answersMap.entries) {
      try {
        final restored = AuditAnswer.fromJson(entry.value);
        final existing = _answers[entry.key];
        if (existing != null) {
          existing.value = restored.value;
          existing.numericValue = restored.numericValue;
          existing.note = restored.note;
          existing.photoUrl = restored.photoUrl;
          existing.repeatedFaultCount = restored.repeatedFaultCount;
          existing.isCcp = restored.isCcp;
          existing.isRisk = restored.isRisk;
        }
      } catch (_) {
        // Skip corrupted answers
      }
    }

    if (draft.notes != null) _notes = draft.notes;
    _pendingDraft = null;
    _recalculateScore();
    notifyListeners();
  }

  /// Discards the pending draft without restoring.
  void discardDraft() {
    if (_draftKey != null) {
      _draftService.deleteDraft(_draftKey!);
    }
    _pendingDraft = null;
    notifyListeners();
  }

  // ---------- Submit (offline-first) ----------
  Future<void> submitAudit() async {
    if (_template == null || _storeId == null) return;

    _isSubmitting = true;
    _error = null;
    _wasQueuedOffline = false;
    // Cancel any pending draft save before submit
    _draftService.dispose();
    notifyListeners();

    try {
      _recalculateScore();

      final idempotencyKey = _uuid.v4();
      final now = DateTime.now();
      final submissionId = _uuid.v4();

      // 1. Save to Drift outbox
      await _outbox.insertSubmission(
        PendingSubmissionsCompanion.insert(
          id: submissionId,
          idempotencyKey: idempotencyKey,
          templateId: _template!.id,
          storeId: _storeId!,
          clientScore: _liveScore ?? 0.0,
          sectionScores: Value(_buildSectionScoresJson()),
          notes: Value(_notes),
          gpsLat: Value(_gpsLat),
          gpsLng: Value(_gpsLng),
          createdAt: now,
          syncStatus: Value('pending'),
        ),
      );

      // 2. Save answers to outbox
      final answerCompanions = _answers.values.map((a) {
        return PendingAnswersCompanion.insert(
          id: _uuid.v4(),
          pendingSubmissionId: submissionId,
          criteriaId: a.criteriaId,
          value: Value(a.value),
          numericValue: Value(a.numericValue),
          note: Value(a.note),
          photoUrl: Value(a.photoUrl),
          isRepeatedError: Value(a.isRepeatedError),
        );
      }).toList();

      await _outbox.insertAnswers(answerCompanions);

      // 2.5. Delete draft now that submission is safely in outbox
      if (_draftKey != null) {
        await _draftService.deleteDraft(_draftKey!);
        _draftSavedAt = null;
      }

      // 3. If online, attempt immediate API submission
      final isOnline = _connectivity?.isOnline ?? true;
      if (isOnline) {
        try {
          final request = CreateSubmissionRequest(
            templateId: _template!.id,
            storeId: _storeId!,
            clientScore: _liveScore,
            sectionScores: _buildSectionScoresJson(),
            notes: _notes,
            gpsLat: _gpsLat,
            gpsLng: _gpsLng,
            answers: _answers.values.map((a) => a.toInput()).toList(),
            idempotencyKey: idempotencyKey,
          );

          _lastSubmission = await _api.createSubmission(request);

          // Success — remove from outbox
          await _outbox.removeSubmission(submissionId);
        } catch (_) {
          // API failed — submission stays in outbox for sync
          _wasQueuedOffline = true;
        }
      } else {
        _wasQueuedOffline = true;
      }
    } catch (e) {
      _error = 'Submission failed. Please try again.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ---------- Pending count ----------
  Future<int> get pendingCount => _outbox.pendingCount();

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
    notifyListeners();
  }
}
