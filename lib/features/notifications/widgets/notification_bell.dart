import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/notification_manager.dart';

final _di = GetIt.instance;

/// Bell icon widget for AppBar — shows unread count badge.
/// Tapping navigates to the notification drawer page.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final NotificationManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<NotificationManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadNotifications();
    });
    _manager.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _manager.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _manager.unreadCount;

    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Notifications',
    );
  }
}
