import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/services/api_client.dart';
import '../model/auth_state.dart';
import '../model/user_session.dart';
import '../services/auth_api_service.dart';
import '../services/secure_storage_service.dart';

final _di = GetIt.instance;

/// PFA Manager for authentication.
///
/// Manages login, logout, auto-login, and session state.
/// UI watches [authState] and [currentUser] via WatchingWidget.
class AuthManager extends ChangeNotifier {
  final AuthApiService _authApi;
  final SecureStorageService _storage;
  final ApiClient _apiClient;

  AuthManager({
    AuthApiService? authApi,
    SecureStorageService? storage,
    ApiClient? apiClient,
  }) : _authApi = authApi ?? _di<AuthApiService>(),
       _storage = storage ?? _di<SecureStorageService>(),
       _apiClient = apiClient ?? _di<ApiClient>();

  // ---------- State ----------
  final _authState = ValueNotifier<AuthState>(AuthState.loading);
  ValueListenable<AuthState> get authState => _authState;

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;

  // ---------- Login ----------
  Future<void> login(String email, String password) async {
    _authState.value = AuthState.loading;
    notifyListeners();

    try {
      final session = await _authApi.login(email, password);

      // Persist
      await _storage.saveToken(session.token);
      await _storage.saveSession(session);

      // Set API auth header
      _apiClient.setAuthToken(session.token);

      // Update state
      _currentUser = session;
      _authState.value = AuthState.authenticated;
      notifyListeners();
    } catch (e) {
      _authState.value = AuthState.unauthenticated;
      notifyListeners();
      rethrow; // Let UI handle the error
    }
  }

  // ---------- Auto Login ----------
  Future<void> tryAutoLogin() async {
    _authState.value = AuthState.loading;
    notifyListeners();

    try {
      final session = await _storage.getSession();
      final token = await _storage.getToken();

      if (session != null && token != null) {
        _apiClient.setAuthToken(token);
        _currentUser = session;
        _authState.value = AuthState.authenticated;
      } else {
        _authState.value = AuthState.unauthenticated;
      }
    } catch (_) {
      _authState.value = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  // ---------- Logout ----------
  Future<void> logout() async {
    await _storage.clearAll();
    _apiClient.clearAuthToken();
    _currentUser = null;
    _authState.value = AuthState.unauthenticated;
    notifyListeners();
  }
}
