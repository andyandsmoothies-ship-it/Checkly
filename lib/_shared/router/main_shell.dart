import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/manager/notification_manager.dart';
import '../../features/notifications/model/notification_dto.dart';
import '../services/sync_engine.dart';
import '../theme/app_theme.dart';
import '../../features/auth/manager/auth_manager.dart';
import 'nav_item.dart';
import 'shell_tab.dart';

final _di = GetIt.instance;

/// SC-4: MainShell with bottom navigation (2–6 tabs based on capabilities).
/// Tab definitions → shell_tab.dart. Nav item widget → nav_item.dart.
///
/// Capability-gated tabs are hidden entirely when the user lacks the required cap.
/// The active tab highlight is computed from the visible tab list — not fixed positions —
/// so the correct tab is highlighted even when optional tabs are hidden.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

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
              stream: _di<SyncEngine>().watchExhaustedCount(),
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
                              await _di<SyncEngine>().discardExhausted();
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
                            await _di<SyncEngine>().requeueExhausted();
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
            // Single ValueListenableBuilder covers all capability-gated tabs.
            // Rebuilds the row when AuthManager.capabilities changes
            // (e.g., after an admin assigns or removes a capability in real time).
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: _di<AuthManager>().capabilities,
              builder: (context, caps, _) {
                // Filter the full tab list to only those the user can access.
                final visibleTabs = ShellTab.all.where((tab) {
                  return tab.requiredCapability == null ||
                      caps.contains(tab.requiredCapability);
                }).toList();

                // Determine which visible tab matches the current route.
                // Clamp to 0 (Home) if no tab matches (e.g., user is on /admin).
                final activeIndex = () {
                  final idx = visibleTabs.indexWhere(
                    (tab) => location.startsWith(tab.route),
                  );
                  return idx < 0 ? 0 : idx;
                }();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < visibleTabs.length; i++)
                      _buildNavItem(
                        context,
                        tab: visibleTabs[i],
                        isActive: i == activeIndex,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single nav item. INBOX gets a nested badge-count listener.
  Widget _buildNavItem(
    BuildContext context, {
    required ShellTab tab,
    required bool isActive,
  }) {
    if (tab.route == '/inbox') {
      return ValueListenableBuilder<List<NotificationDto>>(
        valueListenable: _di<NotificationManager>().notifications,
        builder: (context, items, _) {
          final unread = items.where((n) => !n.isRead).length;
          return NavItem(
            icon: tab.icon,
            label: tab.label,
            isActive: isActive,
            onTap: () => context.go(tab.route),
            badgeCount: unread,
          );
        },
      );
    }

    return NavItem(
      icon: tab.icon,
      label: tab.label,
      isActive: isActive,
      onTap: () => context.go(tab.route),
    );
  }
}
