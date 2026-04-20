import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../services/admin_api_service.dart';
import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';

final _di = GetIt.instance;

/// PFA Manager for Admin Store Management page.
///
/// Wraps the READ operations (getStores + getAreas) that were previously
/// called directly from [StoreManagementPage]. Mutation operations
/// (createStore, updateStore, toggleActive) remain in the page because
/// they close sheets and trigger navigation.
class AdminStoreManager extends ChangeNotifier {
  final StoreApiService _storeApi;
  final AdminApiService _adminApi;

  AdminStoreManager({StoreApiService? storeApi, AdminApiService? adminApi})
    : _storeApi = storeApi ?? _di<StoreApiService>(),
      _adminApi = adminApi ?? _di<AdminApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<StoreDto> stores = [];
  List<Map<String, dynamic>> areas = [];

  // ---------- Load ----------
  Future<void> load({String? areaId}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final storesFuture = _storeApi.getStores(
        includeInactive: true,
        areaId: areaId,
      );
      final areasFuture = _adminApi.getAreas();

      stores = await storesFuture;
      areas = await areasFuture;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
