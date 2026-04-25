import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../services/admin_api_service.dart';
import '../../stores/services/store_api_service.dart';
import '../../templates/services/template_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for the Admin Dashboard stats panel.
///
/// Wraps the 3 parallel API reads (user count, store count, template count)
/// that were previously called via `_loadCounts()` directly in [AdminDashboardPage].
/// The [DashboardManager] continues to own the open action plans count.
class AdminDashboardManager extends ChangeNotifier {
  final AdminApiService _adminApi;
  final StoreApiService _storeApi;
  final TemplateApiService _templateApi;

  AdminDashboardManager({
    AdminApiService? adminApi,
    StoreApiService? storeApi,
    TemplateApiService? templateApi,
  }) : _adminApi = adminApi ?? _di<AdminApiService>(),
       _storeApi = storeApi ?? _di<StoreApiService>(),
       _templateApi = templateApi ?? _di<TemplateApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  int userCount = 0;
  int storeCount = 0;
  int templateCount = 0;

  // ---------- Load ----------
  Future<void> loadCounts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _adminApi.getUsersRaw(pageSize: 1),
        _storeApi.getStores(),
        _templateApi.getTemplates(),
      ]);

      final usersResponse = results[0] as Map<String, dynamic>;
      final stores = results[1] as List<dynamic>;
      final templates = results[2] as List<dynamic>;

      userCount = usersResponse['total'] as int? ?? 0;
      storeCount = stores.length;
      templateCount = templates.length;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
