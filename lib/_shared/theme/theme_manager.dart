import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeKey = 'app_theme_mode';

/// Manages light/dark theme preference with persistence.
///
/// Reads the saved preference on [init], exposes [themeMode] for the
/// MaterialApp to listen to, and persists changes via flutter_secure_storage.
class ThemeManager extends ChangeNotifier {
  final FlutterSecureStorage _storage;

  ThemeManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(
        aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
      );

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  /// Call during app startup to load persisted theme preference.
  Future<void> init() async {
    final saved = await _storage.read(key: _themeKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Toggle between light and dark mode.
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await _storage.write(key: _themeKey, value: _themeMode.name);
    notifyListeners();
  }

  /// Set a specific theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.write(key: _themeKey, value: mode.name);
    notifyListeners();
  }
}
