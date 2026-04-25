import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'notification_manager.dart';

final _di = GetIt.instance;

class NotificationSyncManager {
  final NotificationManager _notificationManager;
  final FlutterLocalNotificationsPlugin _localNotifications;

  Timer? _debounce;

  NotificationSyncManager({
    NotificationManager? notificationManager,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _notificationManager = notificationManager ?? _di<NotificationManager>(),
        _localNotifications = localNotifications ?? _di<FlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {},
      onDidReceiveBackgroundNotificationResponse: null,
    );
  }

  void onTickle() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _handleTickle();
    });
  }

  Future<void> _handleTickle() async {
    try {
      final fresh = await _notificationManager
          .refreshDelta()
          .timeout(const Duration(seconds: 15));

      if (fresh.isNotEmpty) {
        final newest = fresh.first;
        await _showLocalNotification(
          title: newest.title,
          body: newest.message ?? '',
        );
      }
    } catch (e) {
      await _showLocalNotification(
        title: 'New Activity',
        body: 'New Activity detected',
      );
    }
  }

  Future<void> _showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'checkly_notifications',
      'Checkly Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void dispose() {
    _debounce?.cancel();
  }
}
