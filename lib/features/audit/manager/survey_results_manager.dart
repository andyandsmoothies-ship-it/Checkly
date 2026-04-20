import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../model/survey_result_dto.dart';
import '../services/submission_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for the Survey Results page.
///
/// Wraps the direct [SubmissionApiService.getSurveyResults] call
/// from the old [SurveyResultsPage] into a proper Manager layer.
/// Scoped by [templateId] passed to [load()].
class SurveyResultsManager extends ChangeNotifier {
  final SubmissionApiService _api;

  SurveyResultsManager({SubmissionApiService? api})
    : _api = api ?? _di<SubmissionApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<SurveyQuestionResult> results = [];

  // ---------- Load ----------
  Future<void> load(String templateId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      results = await _api.getSurveyResults(templateId);
    } catch (e) {
      error = 'Failed to load survey results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
