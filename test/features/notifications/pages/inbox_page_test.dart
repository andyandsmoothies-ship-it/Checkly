/// Widget Tests for InboxPage (Slice 1)
/// ======================================
/// Target: InboxPage — tab filtering and markAllRead behavior
///
/// Test Contracts:
///   TC1.2b: "All" tab shows all notifications regardless of read status
///   TC1.2c: "Unread" tab shows only items where isRead == false
///   TC1.3b: After markAllRead(), Unread tab item list is empty
///
/// Strategy: Register a concrete NotificationManager subclass into GetIt
/// scope. The subclass pre-seeds notifications.value and overrides
/// loadNotifications/markAllRead to be no-ops (no real API/DB calls).

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/features/notifications/pages/inbox_page.dart';
import 'package:checkly/features/notifications/manager/notification_manager.dart';
import 'package:checkly/features/notifications/model/notification_dto.dart';

// ─── Test double ───

/// Minimal NotificationManager that avoids all real I/O.
/// Extends ChangeNotifier directly to bypass the parent constructor's
/// dependency on NotificationApiService and NotificationDao.
class _StubNotificationManager extends ChangeNotifier
    implements NotificationManager {
  @override
  final ValueNotifier<List<NotificationDto>> notifications;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  int _unreadCount;

  @override
  int get unreadCount => _unreadCount;

  @override
  String? get error => null;

  _StubNotificationManager(List<NotificationDto> seed)
      : notifications = ValueNotifier(seed),
        _unreadCount = seed.where((n) => !n.isRead).length;

  @override
  Future<void> loadNotifications() async {
    // No-op — already seeded
  }

  @override
  Future<void> markAllRead() async {
    final now = DateTime.now();
    notifications.value = notifications.value.map((n) {
      if (!n.isRead) {
        return NotificationDto(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          message: n.message,
          readAt: now,
          actionUrl: n.actionUrl,
          metadata: n.metadata,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final now = DateTime.now();
    notifications.value = notifications.value.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return NotificationDto(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          message: n.message,
          readAt: now,
          actionUrl: n.actionUrl,
          metadata: n.metadata,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    _unreadCount = notifications.value.where((n) => !n.isRead).length;
    notifyListeners();
  }

  @override
  Future<void> onPushNotification(NotificationDto notification) async {}

  @override
  Future<List<NotificationDto>> refreshDelta() async => [];
}

// ─── Test data ───

final _now = DateTime.now();

NotificationDto _makeNotif({
  required String id,
  required bool isRead,
}) =>
    NotificationDto(
      id: id,
      userId: 'u1',
      type: 'test',
      title: 'Test $id',
      message: 'Message $id',
      readAt: isRead ? _now.subtract(const Duration(hours: 1)) : null,
      createdAt: _now,
    );

// ─── Widget harness ───

Widget _buildHarness() {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/inbox',
      routes: [
        GoRoute(
          path: '/inbox',
          builder: (context, state) => const InboxPage(),
        ),
      ],
    ),
  );
}

// ─── Tests ───

void main() {
  setUp(() {
    // Push a fresh scope for each test so registrations don't leak
    GetIt.I.pushNewScope();
  });

  tearDown(() async {
    await GetIt.I.popScope();
  });

  group('InboxPage — Tab Filtering', () {
    testWidgets(
      'TC1.2b: All tab shows all notifications (read + unread)',
      (tester) async {
        GetIt.I.registerSingleton<NotificationManager>(
          _StubNotificationManager([
            _makeNotif(id: 'n1', isRead: true),
            _makeNotif(id: 'n2', isRead: false),
            _makeNotif(id: 'n3', isRead: false),
          ]),
        );

        await tester.pumpWidget(_buildHarness());
        await tester.pumpAndSettle();

        // Default tab is "All" — all 3 messages should be visible
        expect(find.text('Message n1'), findsOneWidget);
        expect(find.text('Message n2'), findsOneWidget);
        expect(find.text('Message n3'), findsOneWidget);
      },
    );

    testWidgets(
      'TC1.2c: Unread tab shows only unread notifications',
      (tester) async {
        GetIt.I.registerSingleton<NotificationManager>(
          _StubNotificationManager([
            _makeNotif(id: 'n1', isRead: true),
            _makeNotif(id: 'n2', isRead: false),
            _makeNotif(id: 'n3', isRead: false),
          ]),
        );

        await tester.pumpWidget(_buildHarness());
        await tester.pumpAndSettle();

        // Tap the "Unread" tab
        await tester.tap(find.text('Unread'));
        await tester.pumpAndSettle();

        // Only unread items (n2, n3) should be visible
        expect(find.text('Message n1'), findsNothing);
        expect(find.text('Message n2'), findsOneWidget);
        expect(find.text('Message n3'), findsOneWidget);
      },
    );

    testWidgets(
      'TC1.3b: After markAllRead(), Unread tab becomes empty',
      (tester) async {
        GetIt.I.registerSingleton<NotificationManager>(
          _StubNotificationManager([
            _makeNotif(id: 'n1', isRead: false),
            _makeNotif(id: 'n2', isRead: false),
          ]),
        );

        await tester.pumpWidget(_buildHarness());
        await tester.pumpAndSettle();

        // Tap "Mark all read" button in the AppBar
        await tester.tap(find.text('Mark all read'));
        await tester.pumpAndSettle();

        // Switch to Unread tab
        await tester.tap(find.text('Unread'));
        await tester.pumpAndSettle();

        // Unread tab should show the empty state message
        expect(find.text('No unread notifications'), findsOneWidget);
        expect(find.text('Message n1'), findsNothing);
        expect(find.text('Message n2'), findsNothing);
      },
    );
  });
}
