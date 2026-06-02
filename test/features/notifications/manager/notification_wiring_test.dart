import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';

import 'package:checkly/features/notifications/manager/notification_sync_manager.dart';
import 'package:checkly/features/auth/manager/auth_manager.dart';
import 'package:checkly/_shared/theme/app_theme_notifier.dart';
import 'package:checkly/main.dart';

class MockNotificationSyncManager extends Mock
    implements NotificationSyncManager {}

class MockAuthManager extends Mock implements AuthManager {}

void main() {
  late MockNotificationSyncManager mockSyncManager;
  late MockAuthManager mockAuthManager;

  setUp(() {
    mockSyncManager = MockNotificationSyncManager();
    mockAuthManager = MockAuthManager();

    GetIt.instance.registerSingleton<NotificationSyncManager>(mockSyncManager);
    GetIt.instance.registerSingleton<AuthManager>(mockAuthManager);
    GetIt.instance.registerSingleton<ThemeSpiritNotifier>(ThemeSpiritNotifier());
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
