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
  List<StoreDto> _allStores = [];
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
        cached.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        stores.value = cached;
        _allStores = List.from(cached);
        isLoading.value = false;
        notifyListeners();
      }

      // 2. Background API fetch
      try {
        final fresh = await _api.getStores();
        fresh.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        stores.value = fresh;
        _allStores = List.from(fresh);
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

  // ---------- Search (in-memory, offline-safe) ----------
  Future<void> searchStores(String query) async {
    if (query.isEmpty) {
      stores.value = List.from(_allStores);
    } else {
      final q = query.toLowerCase();
      stores.value = _allStores
          .where((s) => s.name.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }
}
