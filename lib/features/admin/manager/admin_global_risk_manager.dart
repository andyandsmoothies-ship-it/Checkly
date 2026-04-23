import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for Admin Global Risk Management page.
///
/// Wraps the READ operation (getGlobalRisks). Mutation operations
/// (create, update, delete) remain in the page because they involve
/// dialog-local error state and inline snackbar feedback tightly
/// coupled to the sheet context. This mirrors [AdminAreaManager].
class AdminGlobalRiskManager extends ChangeNotifier {
  final AdminApiService _api;

  AdminGlobalRiskManager({AdminApiService? api})
    : _api = api ?? _di<AdminApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> risks = [];

  // ---------- Load ----------
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      risks = await _api.getGlobalRisks();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
