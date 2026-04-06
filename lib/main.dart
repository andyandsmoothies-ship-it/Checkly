import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import '_shared/router/app_router.dart';
import '_shared/theme/app_theme.dart';
import '_shared/theme/theme_manager.dart';
import 'features/auth/manager/auth_manager.dart';
import 'features/audit/services/draft_service.dart';
import 'locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();

  // GC: Clean up expired drafts (>14 days per ADR-001) + orphaned photo files.
  // Runs on every cold boot. Errors are swallowed — GC must never crash startup.
  try {
    await DraftService().cleanExpired();
  } catch (_) {}

  // Load persisted theme preference
  await GetIt.instance<ThemeManager>().init();

  // Try auto-login from stored token
  GetIt.instance<AuthManager>().tryAutoLogin();

  runApp(const ChecklyApp());
}


class ChecklyApp extends StatelessWidget {
  const ChecklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = GetIt.instance<ThemeManager>();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) => MaterialApp.router(
        title: 'Checkly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeManager.themeMode,
        routerConfig: appRouter,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
