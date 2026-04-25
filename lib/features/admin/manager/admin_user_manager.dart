import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../auth/manager/auth_manager.dart';
import '../../stores/services/store_api_service.dart';
import '../services/admin_api_service.dart';

final _di = GetIt.instance;

// ── Typed Exceptions ──────────────────────────────────────────────────────────

/// Thrown by [AdminUserManager.saveUser] when the target position (SM/AM slot)
/// is already occupied. The page catches this to show the transfer dialog.
class TransferConflictException implements Exception {
  /// Human-readable name of the current occupant, e.g. "Nguyen Van A".
  final String existingManagerName;
  const TransferConflictException(this.existingManagerName);
}

/// Thrown by [AdminUserManager.saveUser] when an admin attempts to downgrade
/// their own role — the "Root Suicide" guard.
class RootSuicideException implements Exception {
  const RootSuicideException();
}

// ── Manager ───────────────────────────────────────────────────────────────────

/// PFA Manager for Admin User Management.
///
/// Owns ALL state and ALL network mutations for the User Management screen:
/// - READ: [load], [loadStores]
/// - WRITE: [banUser], [saveUser], [resetPassword], [createUser]
///
/// The page is responsible only for:
/// - Dialog/bottom-sheet UX coordination
/// - Catching typed exceptions ([TransferConflictException], [RootSuicideException])
///   and showing the appropriate confirmation dialogs.
class AdminUserManager extends ChangeNotifier {
  final AdminApiService _adminApi;
  final AuthManager _auth;

  AdminUserManager({AdminApiService? adminApi, AuthManager? auth})
    : _adminApi = adminApi ?? _di<AdminApiService>(),
      _auth = auth ?? _di<AuthManager>();

  // ---------- State ----------
  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> areas = [];

  String? get currentUserId => _auth.currentUser?.userId;

  // ---------- READ ----------

  /// Loads user list + areas in parallel. Replaces entire list on success.
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

  // ---------- WRITE ----------

  /// Bans or unbans a user.
  ///
  /// Optimistically updates [users] in-memory on success so the UI reflects
  /// the change without a full reload (prevents Split-Brain on refresh failure).
  ///
  /// Throws [DioException] on network failure — caller (page) shows SnackBar.
  Future<void> banUser(String userId, {required bool ban}) async {
    await _adminApi.banUser(userId, ban: ban);

    // Optimistic in-memory update — avoids _loadData() round-trip.
    final idx = users.indexWhere((u) => u['id'] == userId);
    if (idx != -1) {
      users[idx] = Map<String, dynamic>.from(users[idx])..['isLocked'] = ban;
      notifyListeners();
    }
  }

  /// Updates a user's details (name, role, store, area).
  ///
  /// **Root Suicide Guard:** Throws [RootSuicideException] if the caller
  /// attempts to downgrade the *current* admin's own role.
  ///
  /// **409 Conflict:** Throws [TransferConflictException] with the occupant's
  /// name when the target SM/AM slot is already taken. The page catches this
  /// to show the transfer confirmation dialog.
  ///
  /// On success, updates [users] in-memory.
  Future<void> saveUser(
    String id, {
    String? fullName,
    String? role,
    String? storeId,
    String? areaId,
    bool forceReassign = false,
  }) async {
    // ── Root Suicide Guard ──
    if (id == currentUserId && role != null && role != 'admin') {
      throw const RootSuicideException();
    }

    try {
      final updated = await _adminApi.updateUser(
        id,
        fullName: fullName,
        role: role,
        storeId: storeId,
        areaId: areaId,
        forceReassign: forceReassign,
      );

      // In-memory update — replace the entry, preserving unknown fields.
      _applyUserUpdate(id, updated);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Parse typed 409 payload here so the View never touches raw JSON.
        final data = e.response?.data;
        final name = (data is Map<String, dynamic>)
            ? (data['existingManagerName'] as String? ?? 'another user')
            : 'another user';
        throw TransferConflictException(name);
      }
      rethrow;
    }
  }

  /// Resets a user's password. Delegates to [AdminApiService.resetPassword].
  ///
  /// Throws [DioException] or generic [Exception] on failure — caller handles.
  Future<void> resetPassword(String userId, String newPassword) async {
    await _adminApi.resetPassword(userId, newPassword);
  }

  /// Creates a new user and prepends the result to [users].
  ///
  /// Throws [DioException] on failure — caller handles.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? storeId,
    String? areaId,
  }) async {
    final created = await _adminApi.createUser(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      storeId: storeId,
      areaId: areaId,
    );

    // Prepend so the new user appears at the top without a reload.
    users = [created, ...users];
    notifyListeners();
  }

  // ---------- Helpers ----------

  void _applyUserUpdate(String id, Map<String, dynamic> updated) {
    final idx = users.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      // Merge: server-returned fields override local; unknown fields preserved.
      users[idx] = {...users[idx], ...updated};
    }
    notifyListeners();
  }
}
