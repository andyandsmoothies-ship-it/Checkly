import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../services/admin_api_service.dart';
import '../../stores/services/store_api_service.dart';

final _di = GetIt.instance;

/// PFA Manager for Admin User Management page.
///
/// Wraps the READ operations (getUsers + getAreas) that were previously
/// called directly from [UserManagementPage]. Mutation operations
/// (updateUser, banUser, resetPassword, createUser) remain in the page
/// because they involve complex dialog UX and typed DioException handling.
class AdminUserManager extends ChangeNotifier {
  final AdminApiService _adminApi;

  AdminUserManager({AdminApiService? adminApi})
    : _adminApi = adminApi ?? _di<AdminApiService>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> areas = [];

  // ---------- Load ----------
  Future<void> load({String? search}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final usersFuture = _adminApi.getUsers(
        search: search?.isEmpty == true ? null : search,
      );
      final areasFuture = _adminApi.getAreas();

      users = await usersFuture;
      areas = await areasFuture;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads stores for the user-edit sheet. Not cached — always fresh.
  Future<List<Map<String, dynamic>>> loadStores({
    String? assignableAs,
    String? exceptUser,
  }) async {
    final stores = await _di<StoreApiService>().getStores(
      assignableAs: assignableAs,
      exceptUser: exceptUser,
    );
    return stores
        .map(
          (s) => <String, dynamic>{
            'id': s.id,
            'name': s.name,
            'isActive': s.isActive,
            'managerName': s.managerName,
          },
        )
        .toList();
  }
}
