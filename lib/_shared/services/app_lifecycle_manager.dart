import 'dart:async';
import 'package:flutter/material.dart';

/// 6D: App Lifecycle Manager — handles background/foreground transitions
/// with 4-tier recovery strategy and 500ms debounce.
///
/// Tiers:
/// - <5 min: no-op (fresh state)
/// - 5 min – 12h: auth token check
/// - 12h – 7 days: full data resync
/// - >7 days: force re-login
class AppLifecycleManager with WidgetsBindingObserver {
  DateTime? _lastPausedAt;
  Timer? _debounceTimer;
  VoidCallback? onAuthCheck;
  VoidCallback? onFullResync;
  VoidCallback? onForceReLogin;

  static const _debounceMs = 500;
  static const _tier2 = Duration(minutes: 5);
  static const _tier3 = Duration(hours: 12);
  static const _tier4 = Duration(days: 7);

  @visibleForTesting
  void setLastPausedAt(DateTime time) {
    _lastPausedAt = time;
  }

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _lastPausedAt = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        _debounceTimer?.cancel();
        _debounceTimer = Timer(
          const Duration(milliseconds: _debounceMs),
          _handleResume,
        );
        break;

      default:
        break;
    }
  }

  void _handleResume() {
    if (_lastPausedAt == null) return;

    final elapsed = DateTime.now().difference(_lastPausedAt!);
    _lastPausedAt = null;

    if (elapsed < _tier2) {
      // Tier 1: <5 min → no-op
      return;
    } else if (elapsed < _tier3) {
      // Tier 2: 5 min – 12h → auth check
      onAuthCheck?.call();
    } else if (elapsed < _tier4) {
      // Tier 3: 12h – 7d → full resync
      onFullResync?.call();
    } else {
      // Tier 4: >7d → force re-login
      onForceReLogin?.call();
    }
  }
}
