import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/database/dao/store_dao.dart';
import '../model/store_dto.dart';
import '../services/store_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for stores — cache-first read path.
///
/// `loadStores()`:
/// 1. Read from Drift cache → emit immediately
/// 2. Background API fetch → update Drift → notify listeners
class StoreManager extends ChangeNotifier {
  final StoreApiService _api;
  late final StoreDao _dao;

  StoreManager({StoreApiService? api, StoreDao? dao})
    : _api = api ?? _di<StoreApiService>(),
      _dao = dao ?? StoreDao(_di<DatabaseService>().db);

  // ---------- State ----------
  final stores = ValueNotifier<List<StoreDto>>([]);
  final isLoading = ValueNotifier<bool>(false);
  String? error;
  DateTime? lastRefreshed;

  // ---------- Load (cache-first) ----------
  Future<void> loadStores() async {
    isLoading.value = true;
    error = null;
    notifyListeners();

    try {
      // 1. Read from Drift cache first
      final cached = await _dao.getAllStores();
      if (cached.isNotEmpty) {
        stores.value = cached;
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch
      try {
        final fresh = await _api.getStores();
        stores.value = fresh;
        lastRefreshed = DateTime.now();

        // 3. Update Drift cache
        await _dao.upsertStores(fresh);
      } catch (_) {
        if (cached.isEmpty) {
          error = 'Failed to load stores (offline)';
        }
      }
    } catch (e) {
      error = 'Failed to load stores';
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  // ---------- Search (server-side via B4) ----------
  Future<void> searchStores(String query) async {
    if (query.isEmpty) {
      // Empty query → show cached stores
      final cached = await _dao.getAllStores();
      stores.value = cached;
      notifyListeners();
      return;
    }

    isLoading.value = true;
    notifyListeners();

    try {
      final results = await _api.getStores(search: query);
      stores.value = results;
    } catch (_) {
      // On error, keep current list
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }
}
