import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:checkly/_shared/theme/app_colors.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';
import '../manager/notification_manager.dart';
import '../model/notification_dto.dart';

final _di = GetIt.instance;

/// Full-page notification list grouped by Today/Yesterday/Earlier.
/// Supports mark-as-read on tap and mark-all-read.
class NotificationDrawerPage extends StatefulWidget {
  const NotificationDrawerPage({super.key});

  @override
  State<NotificationDrawerPage> createState() => _NotificationDrawerPageState();
}

class _NotificationDrawerPageState extends State<NotificationDrawerPage> {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_manager.unreadCount > 0)
            TextButton(
              onPressed: () => _manager.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _manager.isLoading,
        builder: (context, loading, _) {
          if (loading && _manager.notifications.value.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<List<NotificationDto>>(
            valueListenable: _manager.notifications,
            builder: (context, items, _) {
              // AC9: Empty state
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
                        'No notifications yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group by Today/Yesterday/Earlier
              final groups = _groupByDate(items);

              return RefreshIndicator(
                onRefresh: () => _manager.loadNotifications(),
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
                        (n) => _NotificationTile(
                          notification: n,
                          onTap: () => _onTapNotification(n),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onTapNotification(NotificationDto notification) {
    // AC7: Mark as read
    if (!notification.isRead) {
      _manager.markAsRead(notification.id);
    }

    // Navigate to action_url if available
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
}

// ─── Notification Tile ───

class _NotificationTile extends StatelessWidget {
  final NotificationDto notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isRead
        ? (isLight ? Colors.white : Colors.transparent)
        : (isLight
              ? AppColors.iguana
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.15));

    return StrokeCard(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isRead
              ? (isLight
                    ? AppColors.swan
                    : theme.colorScheme.surfaceContainerHighest)
              : AppColors.featherGreen,
          child: Icon(
            Icons.notifications,
            size: 18,
            color: isRead
                ? (isLight
                      ? AppColors.wolf
                      : theme.colorScheme.onSurfaceVariant)
                : Colors.white,
          ),
        ),
        title: Text(
          notification.message ?? 'Notification',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
            fontFamily: 'Nunito',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTime(notification.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: 'Nunito',
          ),
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.featherGreen,
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
