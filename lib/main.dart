import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import '_shared/router/app_router.dart';
import '_shared/theme/app_theme.dart';
import '_shared/theme/app_theme_notifier.dart';
import 'features/auth/manager/auth_manager.dart';
import 'features/audit/services/draft_service.dart';
import 'features/notifications/manager/notification_sync_manager.dart';
import 'locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  // ── DIAGNOSTIC INSTRUMENT (temporary) ─────────────────────────────────
  // Captures the exact exception message when the BOD dashboard freezes.
  // Remove after root cause is confirmed.
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('════════════════════════════════════════');
    debugPrint('🔴 FLUTTER ERROR CAUGHT');
    debugPrint('  Exception : ${details.exception}');
    debugPrint('  Library   : ${details.library}');
    debugPrint('  Context   : ${details.context}');
    debugPrint('  Stack     :\n${details.stack}');
    debugPrint('════════════════════════════════════════');
    FlutterError.presentError(details); // still show red screen in debug
  };

  // GC: Clean up expired drafts (>14 days per ADR-001) + orphaned photo files.
  // Runs on every cold boot. Errors are swallowed — GC must never crash startup.
  try {
    await DraftService().cleanExpired();
  } catch (_) {}

  // Initialize Notification Sync Engine
  // Errors are swallowed — must never crash startup.
  try {
    await GetIt.instance<NotificationSyncManager>().init();
  } catch (e, s) {
    debugPrint('NotificationSyncManager init failed: $e\n$s');
  }

  // Try auto-login from stored token
  GetIt.instance<AuthManager>().tryAutoLogin();

  // Secondary safety net: catches errors from platform/isolate level
  // (e.g. exceptions thrown inside async functions, Future chains, etc.)
  // This fires BEFORE the Dart debugger can intercept paused exceptions.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('════════════════════════════════════════');
    debugPrint('🔴 PLATFORM ERROR CAUGHT');
    debugPrint('  Error : $error');
    debugPrint('  Stack :\n$stack');
    debugPrint('════════════════════════════════════════');
    return true; // mark as handled so the app doesn't terminate
  };

  runApp(const ChecklyApp());
}

class ChecklyApp extends StatefulWidget {
  const ChecklyApp({super.key});

  @override
  State<ChecklyApp> createState() => _ChecklyAppState();
}

class _ChecklyAppState extends State<ChecklyApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        GetIt.instance<AuthManager>().refreshCapabilities();
        GetIt.instance<NotificationSyncManager>().onTickle();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spiritNotifier = GetIt.instance<ThemeSpiritNotifier>();
    return ValueListenableBuilder<ThemeSpirit>(
      valueListenable: spiritNotifier,
      builder: (context, spirit, _) {
        return MaterialApp.router(
          title: 'Checkly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
          locale: const Locale('vi', 'VN'),
          supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
