import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A custom, reactive state notifier that manages the active visual spirit.
///
/// Integrates with the [GetIt] locator to provide dynamic theme switching.
/// Automatically updates the legacy static [AppTheme.activeSpirit] to ensure
/// compatibility with any callsites reading directly from it.
class ThemeSpiritNotifier extends ValueNotifier<ThemeSpirit> {
  ThemeSpiritNotifier() : super(ThemeSpirit.duolingo) {
    // Keep legacy static activeSpirit in sync
    AppTheme.activeSpirit = value;
  }

  /// Toggles between Duolingo 3D and Minimalist Flat design spirit.
  void toggleSpirit() {
    state = value == ThemeSpirit.duolingo
        ? ThemeSpirit.minimalist
        : ThemeSpirit.duolingo;
  }

  /// Gets the current design spirit.
  ThemeSpirit get state => value;

  /// Sets a new design spirit, updating legacy static variable and notifying listeners.
  set state(ThemeSpirit newSpirit) {
    if (value == newSpirit) return;
    value = newSpirit;
    AppTheme.activeSpirit = newSpirit;
    notifyListeners();
  }
}
