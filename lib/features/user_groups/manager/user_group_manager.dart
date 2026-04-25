import 'package:flutter/foundation.dart';

import '../model/user_group_dto.dart';
import '../services/user_group_api_service.dart';

/// PFA Manager for UserGroups feature.
///
/// Manages 4-state lifecycle: loading → success/empty/error.
/// UI listens via [ListenableBuilder] or [WatchingWidget].
class UserGroupManager extends ChangeNotifier {
  final UserGroupApiService _api;

  UserGroupManager(this._api);

  // ── State ──────────────────────────────────────────────────────────────────

  List<UserGroupDto> groups = [];
  bool isLoading = false;
  String? error;

  // ── Commands ───────────────────────────────────────────────────────────────

  /// Fetches all user groups from the API.
  /// Sets [isLoading] during fetch; captures [error] on failure.
  Future<void> loadGroups() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      groups = await _api.listGroups();
    } catch (e) {
      error = _friendlyError(e);
      groups = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new user group and refreshes the list on success.
  /// Returns `true` on success, `false` on failure (error is set).
  Future<bool> createGroup(String name, String? description) async {
    try {
      final created = await _api.createGroup(name, description);
      groups = [created, ...groups]; // Prepend for immediate feedback
      notifyListeners();
      return true;
    } catch (e) {
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('403')) {
      return 'You do not have permission to manage user groups.';
    }
    if (msg.contains('401')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
