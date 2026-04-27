import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';
import 'package:checkly/features/notifications/manager/notification_manager.dart';
import 'package:checkly/features/notifications/model/notification_dto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// The class we are testing. (Will fail to compile until Builder implements it).
import 'package:checkly/features/notifications/manager/notification_sync_manager.dart';

class MockNotificationManager extends Mock implements NotificationManager {}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
  });
  late MockNotificationManager mockNotificationManager;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  // Use dynamic to bypass missing class syntax errors during initial RED phase,
  // or define the expected type if it were present. Since it's absent, this will
  // cause a compiler error that we expect.
  late NotificationSyncManager manager;

  setUp(() {
    mockNotificationManager = MockNotificationManager();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();

    // Stub initialization of local notifications
    when(
      () => mockLocalNotifications.initialize(
        any(),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);

    // Assuming the constructor takes these dependencies
    manager = NotificationSyncManager(
      notificationManager: mockNotificationManager,
      localNotifications: mockLocalNotifications,
    );

    manager.init();
  });

  tearDown(() {
    manager.dispose();
  });

  test(
    'TC3.1: NotificationSyncManager_DebouncesMultipleTicklesIntoSingleFetch',
    () {
      fakeAsync((async) {
        when(
          () => mockNotificationManager.refreshDelta(),
        ).thenAnswer((_) async => []);

        manager.onTickle();
        manager.onTickle();
        manager.onTickle();

        // Debounce time is 2 seconds.
        // At 1.5 seconds, no fetch should have happened yet.
        async.elapse(const Duration(milliseconds: 1500));
        verifyNever(() => mockNotificationManager.refreshDelta());

        // At 2.5 seconds, the 2-second debounce from the LAST tickle has passed.
        async.elapse(const Duration(milliseconds: 1000));
        verify(() => mockNotificationManager.refreshDelta()).called(1);
      });
    },
  );

  test('TC3.2: NotificationSyncManager_Success_ShowsSpecificBanner', () {
    fakeAsync((async) {
      final mockDto = NotificationDto(
        id: '1',
        userId: 'user1',
        type: 'test_type',
        title: 'New Audit',
        message: 'You have a new audit',
        createdAt: DateTime.now(),
      );

      when(
        () => mockNotificationManager.refreshDelta(),
      ).thenAnswer((_) async => [mockDto]);

      when(
        () => mockLocalNotifications.show(any(), any(), any(), any()),
      ).thenAnswer((_) async {});

      manager.onTickle();
      async.elapse(const Duration(seconds: 3));

      verify(() => mockNotificationManager.refreshDelta()).called(1);
      verify(
        () => mockLocalNotifications.show(
          any(),
          'New Audit',
          'You have a new audit',
          any(),
        ),
      ).called(1);
    });
  });

  test('TC3.3: NotificationSyncManager_Empty_ShowsNoBanner', () {
    fakeAsync((async) {
      when(
        () => mockNotificationManager.refreshDelta(),
      ).thenAnswer((_) async => []);

      manager.onTickle();
      async.elapse(const Duration(seconds: 3));

      verify(() => mockNotificationManager.refreshDelta()).called(1);
      verifyNever(
        () => mockLocalNotifications.show(any(), any(), any(), any()),
      );
    });
  });

  test('TC3.4: NotificationSyncManager_Timeout_ShowsFallbackBanner', () {
    fakeAsync((async) {
      // Simulate a fetch that takes 20 seconds
      when(() => mockNotificationManager.refreshDelta()).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 20), () => []),
      );

      when(
        () => mockLocalNotifications.show(any(), any(), any(), any()),
      ).thenAnswer((_) async {});

      manager.onTickle();

      // Elapse 2 seconds for debounce + 15 seconds for timeout + small buffer
      async.elapse(const Duration(seconds: 18));

      // The fallback generic banner should be shown due to the 15s timeout
      verify(
        () => mockLocalNotifications.show(
          any(),
          any(that: contains('Activity')),
          any(that: contains('New Activity detected')),
          any(),
        ),
      ).called(1);
    });
  });
}
