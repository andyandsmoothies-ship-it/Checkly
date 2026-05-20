import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';

final _di = GetIt.instance;

/// PFA Manager for Admin Store Management page.
///
/// Wraps the READ operations (getStores) that were previously called directly
/// from [StoreManagementPage]. Mutation operations (createStore, updateStore,
/// toggleActive) remain in the page because they close sheets and trigger
/// navigation.
class AdminStoreManager extends ChangeNotifier {
  final StoreApiService _storeApi;

  AdminStoreManager({StoreApiService? storeApi})
    : _storeApi = storeApi ?? _di<StoreApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<StoreDto> stores = [];

  // ---------- Load ----------
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      stores = await _storeApi.getStores(
        includeInactive: true,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
