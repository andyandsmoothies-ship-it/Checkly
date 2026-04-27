import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../_shared/services/api_client.dart';
import '../../../_shared/database/dao/policy_dao.dart';
import '../model/auth_state.dart';
import '../model/user_session.dart';
import '../services/auth_api_service.dart';
import '../services/policy_api_service.dart';
import '../services/secure_storage_service.dart';
import '../../../_shared/database/database_service.dart';

/// PFA Manager for authentication.
///
/// Manages login, logout, auto-login, and session state.
/// UI watches [authState] and [currentUser] via WatchingWidget.
///
/// PBAC Slice 4: exposes [capabilities] as a [ValueListenable<Set<String>>].
/// Capabilities are fetched from the backend on active login and persisted to
/// the local [PolicyDao] table for offline access on app restart.
class AuthManager extends ChangeNotifier {
  final AuthApiService _authApi;
  final SecureStorageService _storage;
  final ApiClient _apiClient;
  final PolicyApiService _policyApi;
  final PolicyDao _policyDao;
  final DatabaseService _dbService;

  AuthManager({
    required AuthApiService authApi,
    required SecureStorageService storage,
    required ApiClient apiClient,
    required PolicyApiService policyApi,
    required PolicyDao policyDao,
    required DatabaseService dbService,
  }) : _authApi = authApi,
       _storage = storage,
       _apiClient = apiClient,
       _policyApi = policyApi,
       _policyDao = policyDao,
       _dbService = dbService;

  // ---------- State ----------
  final _authState = ValueNotifier<AuthState>(AuthState.loading);
  ValueListenable<AuthState> get authState => _authState;

  /// The current user's PBAC capability set.
  /// Populated on login, restored from Drift on tryAutoLogin, cleared on logout.
  /// Consumers (Slice 6) use this to gate feature access.
  final _capabilities = ValueNotifier<Set<String>>({});
  ValueListenable<Set<String>> get capabilities => _capabilities;

  UserSession? _currentUser;
  UserSession? get currentUser => _currentUser;

  // ---------- Login ----------
  Future<void> login(String email, String password) async {
    _authState.value = AuthState.loading;
    notifyListeners();

    try {
      final session = await _authApi.login(email, password);

      // Persist session to secure storage
      await _storage.saveToken(session.token);
      await _storage.saveSession(session);

      // Set API auth header so subsequent calls include the JWT
      _apiClient.setAuthToken(session.token);

      // Update in-memory session
      _currentUser = session;

      // [PBAC Slice 4] Fetch and persist capabilities — fail-open.
      // If the capability endpoint is down or returns an error, login still
      // succeeds. The capabilities default to an empty set; Slice 6 gates will
      // deny access to gated features until the next successful login.
      try {
        final caps = await _policyApi.fetchCapabilities();
        await _policyDao.upsertCapabilities(caps);
        _capabilities.value = caps.toSet();
      } catch (e) {
        debugPrint('[PBAC] Capability sync failed (non-fatal): $e');
        // capabilities remain as previous value (empty on first login)
      }

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

        // [PBAC Slice 4] Restore capabilities from local Drift cache — no network call.
        // Guarantees offline resilience: app restarts without internet still get the
        // capability set that was valid at the time of the last active login.
        _capabilities.value = await _policyDao.getCapabilities();

        _authState.value = AuthState.authenticated;

        // [PBAC Slice 4] Trigger fire-and-forget background refresh to close revocation lag.
        unawaited(refreshCapabilities());
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
    await _dbService.db
        .clearAllData(); // Full SQLite wipe to prevent data bleed
    await _policyDao.clearCapabilities(); // [PBAC Slice 4] clear Drift cache
    _apiClient.clearAuthToken();
    _currentUser = null;
    _capabilities.value = {}; // [PBAC Slice 4] clear memory cache
    _authState.value = AuthState.unauthenticated;
    notifyListeners();
  }

  // ---------- Capability Refresh (Slice 1) ----------
  DateTime? _lastCapabilityRefresh;

  /// Fetches fresh capabilities triggered by app foreground events.
  /// Includes a 5-minute cooldown guard to prevent API stampedes.
  Future<void> refreshCapabilities() async {
    // Guard: only refresh if logged in
    if (_authState.value != AuthState.authenticated) return;

    // Guard: 5-minute cooldown
    final now = DateTime.now();
    if (_lastCapabilityRefresh != null &&
        now.difference(_lastCapabilityRefresh!) < const Duration(minutes: 5)) {
      return;
    }
    _lastCapabilityRefresh = now;

    try {
      final caps = await _policyApi.fetchCapabilities();
      await _policyDao.upsertCapabilities(caps);
      _capabilities.value = caps.toSet();
    } catch (e) {
      debugPrint('[PBAC] Foreground refresh failed (non-fatal): $e');
    }
  }
}
