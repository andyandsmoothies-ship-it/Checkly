import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/user_session.dart';

/// Wraps [FlutterSecureStorage] for JWT and session persistence.
/// Uses Android Keystore / iOS Keychain for secure storage.
class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'user_session';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
          );

  // ---------- Token ----------
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ---------- Session ----------
  Future<void> saveSession(UserSession session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  Future<UserSession?> getSession() async {
    final json = await _storage.read(key: _sessionKey);
    if (json == null) return null;
    return UserSession.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> deleteSession() => _storage.delete(key: _sessionKey);

  // ---------- Clear All ----------
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
