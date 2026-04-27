import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:checkly/features/notifications/manager/notification_manager.dart';
import 'package:checkly/features/notifications/model/notification_dto.dart';
import 'package:checkly/features/notifications/services/notification_api_service.dart';
import 'package:checkly/_shared/database/dao/notification_dao.dart';

class MockNotificationApiService extends Mock
    implements NotificationApiService {}

class MockNotificationDao extends Mock implements NotificationDao {}

void main() {
  late NotificationManager manager;
  late MockNotificationApiService api;
  late MockNotificationDao dao;

  setUp(() {
    api = MockNotificationApiService();
    dao = MockNotificationDao();

    manager = NotificationManager(api: api, dao: dao);
  });

  group('NotificationManager —', () {
    final mockNotification = NotificationDto(
      id: 'n1',
      userId: 'u1',
      title: 'Alert',
      message: 'Body',
      type: 'info',
      readAt: null,
      createdAt: DateTime.now(),
      actionUrl: null,
    );

    test('loadNotifications fetches from cache and API', () async {
      when(
        () => dao.getAllNotifications(),
      ).thenAnswer((_) async => [mockNotification]);
      when(
        () => api.getNotifications(since: any(named: 'since')),
      ).thenAnswer((_) async => []);

      await manager.loadNotifications();

      expect(manager.notifications.value, equals([mockNotification]));
      expect(manager.unreadCount, 1);
      verify(() => dao.getAllNotifications()).called(greaterThanOrEqualTo(1));
      verify(() => api.getNotifications(since: null)).called(1);
    });

    test('markAsRead updates cache and triggers API', () async {
      when(() => dao.markAsRead(any(), any())).thenAnswer((_) async {});
      when(() => dao.getAllNotifications()).thenAnswer(
        (_) async => [
          NotificationDto(
            id: 'n1',
            userId: 'u1',
            title: 'Alert',
            message: 'Body',
            type: 'info',
            readAt: DateTime.now(),
            createdAt: DateTime.now(),
            actionUrl: null,
          ),
        ],
      );
      when(() => api.markAsRead(any())).thenAnswer((_) async {});

      await manager.markAsRead('n1');

      verify(() => dao.markAsRead('n1', any())).called(1);
      verify(() => api.markAsRead('n1')).called(1);
      expect(manager.unreadCount, 0);
    });
  });
}
