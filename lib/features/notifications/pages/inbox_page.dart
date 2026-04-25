import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/notification_manager.dart';
import '../model/notification_dto.dart';

final _di = GetIt.instance;

/// Inbox Center — full-page notification tab with All/Unread filter tabs.
/// This is the 6th shell tab, replacing the AppBar bell pattern.
///
/// State machine:
///   Loading   → CircularProgressIndicator (only when list is empty)
///   Empty     → bell icon + "You're all caught up"
///   Success   → grouped list (Today/Yesterday/Earlier) with tab filter
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late final NotificationManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<NotificationManager>();
    // Gotcha 21: Never call manager methods that notifyListeners() inside
    // initState — defer until the frame is fully built.
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

  void _onTapNotification(NotificationDto notification) {
    if (!notification.isRead) {
      _manager.markAsRead(notification.id);
    }
    final actionUrl = notification.actionUrl;
    if (actionUrl != null && actionUrl.isNotEmpty && mounted) {
      context.push(actionUrl);
    }
  }

  /// Groups notifications into Today / Yesterday / Earlier.
  Map<String, List<NotificationDto>> _groupByDate(List<NotificationDto> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <String, List<NotificationDto>>{};

    for (final item in items) {
      final d = item.createdAt;
      final dateOnly = DateTime(d.year, d.month, d.day);

      String group;
      if (dateOnly == today) {
        group = 'Today';
      } else if (dateOnly == yesterday) {
        group = 'Yesterday';
      } else {
        group = 'Earlier';
      }

      result.putIfAbsent(group, () => []).add(item);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          actions: [
            if (_manager.unreadCount > 0)
              TextButton(
                onPressed: () => _manager.markAllRead(),
                child: const Text('Mark all read'),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
            ],
          ),
        ),
        body: ValueListenableBuilder<bool>(
          valueListenable: _manager.isLoading,
          builder: (context, loading, _) {
            if (loading && _manager.notifications.value.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<List<NotificationDto>>(
              valueListenable: _manager.notifications,
              builder: (context, allItems, _) {
                return TabBarView(
                  children: [
                    _NotificationList(
                      items: allItems,
                      groupByDate: _groupByDate,
                      onTap: _onTapNotification,
                      onRefresh: () => _manager.loadNotifications(),
                    ),
                    _NotificationList(
                      items: allItems.where((n) => !n.isRead).toList(),
                      groupByDate: _groupByDate,
                      onTap: _onTapNotification,
                      onRefresh: () => _manager.loadNotifications(),
                      emptyMessage: 'No unread notifications',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Notification List (shared by both tabs) ───

class _NotificationList extends StatelessWidget {
  final List<NotificationDto> items;
  final Map<String, List<NotificationDto>> Function(List<NotificationDto>)
  groupByDate;
  final void Function(NotificationDto) onTap;
  final Future<void> Function() onRefresh;
  final String emptyMessage;

  const _NotificationList({
    required this.items,
    required this.groupByDate,
    required this.onTap,
    required this.onRefresh,
    this.emptyMessage = "You're all caught up",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final groups = groupByDate(items);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                entry.key,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...entry.value.map(
              (n) => _NotificationTile(notification: n, onTap: () => onTap(n)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Notification Tile (WET copy from notification_drawer_page.dart) ───

class _NotificationTile extends StatelessWidget {
  final NotificationDto notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isRead
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.primary,
          child: Icon(
            Icons.notifications,
            size: 18,
            color: isRead
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimary,
          ),
        ),
        title: Text(
          notification.message ?? 'Notification',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTime(notification.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
