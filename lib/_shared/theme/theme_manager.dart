import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'app_theme_mode';

/// Manages light/dark theme preference with persistence.
///
/// Reads the saved preference on [init], exposes [themeMode] for the
/// MaterialApp to listen to, and persists changes via shared_preferences.
class ThemeManager extends ChangeNotifier {
  final SharedPreferencesAsync _prefs;

  ThemeManager({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  /// Call during app startup to load persisted theme preference.
  Future<void> init() async {
    final saved = await _prefs.getString(_themeKey);
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
    await _prefs.setString(_themeKey, _themeMode.name);
    notifyListeners();
  }

  /// Set a specific theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }
}
