import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/manager/notification_manager.dart';
import '../../features/notifications/model/notification_dto.dart';
import '../database/dao/outbox_dao.dart';
import '../services/sync_engine.dart';
import '../theme/app_theme.dart';

final _di = GetIt.instance;

int _shellIndexFromLocation(String location) {
  if (location.startsWith('/activity')) return 1;
  if (location.startsWith('/plans')) return 2;
  if (location.startsWith('/templates')) return 3;
  if (location.startsWith('/profile')) return 4;
  if (location.startsWith('/admin')) return 4;
  if (location.startsWith('/inbox')) return 5;
  return 0; // /home
}

/// Main shell with 6-tab bottom navigation.
/// Tabs: Home | Activity | Plans | Templates | Profile | Inbox
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _shellIndexFromLocation(location);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          child,
          // --- Pillar D: Exhausted Sync Data Safety Net ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: StreamBuilder<int>(
              stream: _di<OutboxDao>().watchExhaustedCount(),
              initialData: 0,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Theme.of(context).colorScheme.error,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$count unsynced record${count > 1 ? 's' : ''} exhausted',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            // Show confirmation dialog before deleting permanently
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Discard Corrupted Audits?'),
                                content: const Text(
                                  'This will permanently delete the failed audits from this device. '
                                  'They cannot be recovered.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(true),
                                    child: Text(
                                      'Discard',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _di<OutboxDao>().discardExhausted();
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Discard permanently',
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            // Tap to requeue: clears nextRetryAt and retryCount
                            await _di<OutboxDao>().requeueExhausted();
                            // Trigger sync cycle explicitly so records don't just sit there
                            _di<SyncEngine>().requestSync();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: AppTheme.sageGray.withValues(alpha: 0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.grid_view,
                  label: 'HOME',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.assignment,
                  label: 'ACTIVITY',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/activity'),
                ),
                _NavItem(
                  icon: Icons.fact_check,
                  label: 'PLANS',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/plans'),
                ),
                _NavItem(
                  icon: Icons.description_outlined,
                  label: 'TEMPLATES',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/templates'),
                ),
                _NavItem(
                  icon: Icons.account_circle,
                  label: 'PROFILE',
                  isActive: currentIndex == 4,
                  onTap: () => context.go('/profile'),
                ),
                ValueListenableBuilder<List<NotificationDto>>(
                  valueListenable: _di<NotificationManager>().notifications,
                  builder: (context, items, _) {
                    final unread = items.where((n) => !n.isRead).length;
                    return _NavItem(
                      icon: Icons.inbox_outlined,
                      label: 'INBOX',
                      isActive: currentIndex == 5,
                      onTap: () => context.go('/inbox'),
                      badgeCount: unread,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 24, color: color),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 14,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
