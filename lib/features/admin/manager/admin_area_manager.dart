import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for Admin Area Management page.
///
/// Wraps the READ operation (getAreas) that was previously called directly
/// from [AreaManagementPage]. Mutation operations (createArea, updateArea)
/// remain in the page because they involve dialog-local error state and
/// inline snackbar feedback that is tightly coupled to the sheet context.
class AdminAreaManager extends ChangeNotifier {
  final AdminApiService _api;

  AdminAreaManager({AdminApiService? api})
    : _api = api ?? _di<AdminApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> areas = [];

  // ---------- Load ----------
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      areas = await _api.getAreas();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
