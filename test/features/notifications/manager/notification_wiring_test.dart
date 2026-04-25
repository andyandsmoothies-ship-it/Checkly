import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';

import 'package:checkly/features/notifications/manager/notification_sync_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/_shared/theme/theme_manager.dart';
import 'package:checkly/main.dart';

class MockNotificationSyncManager extends Mock
    implements NotificationSyncManager {}

class MockAuthManager extends Mock implements AuthManager {}

class MockThemeManager extends Mock implements ThemeManager {}

void main() {
  late MockNotificationSyncManager mockSyncManager;
  late MockAuthManager mockAuthManager;
  late MockThemeManager mockThemeManager;

  setUp(() {
    mockSyncManager = MockNotificationSyncManager();
    mockAuthManager = MockAuthManager();
    mockThemeManager = MockThemeManager();

    GetIt.instance.registerSingleton<NotificationSyncManager>(mockSyncManager);
    GetIt.instance.registerSingleton<AuthManager>(mockAuthManager);
    GetIt.instance.registerSingleton<ThemeManager>(mockThemeManager);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'TC_Wiring_1: App lifecycle resume triggers NotificationSyncManager.onTickle',
    (tester) async {
      // Arrange
      when(() => mockSyncManager.onTickle()).thenReturn(null);
      when(
        () => mockAuthManager.refreshCapabilities(),
      ).thenAnswer((_) async {});
      when(() => mockThemeManager.themeMode).thenReturn(ThemeMode.light);
      // Note: ThemeManager extends ChangeNotifier, so mock needs addListener
      when(() => mockThemeManager.addListener(any())).thenReturn(null);
      when(() => mockThemeManager.removeListener(any())).thenReturn(null);

      // Act
      await tester.pumpWidget(const ChecklyApp());

      // Simulate app going to background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      // Assert
      verify(() => mockSyncManager.onTickle()).called(1);
      verify(() => mockAuthManager.refreshCapabilities()).called(1);
    },
  );
}
