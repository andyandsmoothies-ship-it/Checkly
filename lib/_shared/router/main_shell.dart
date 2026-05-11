import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/manager/notification_manager.dart';
import '../../features/notifications/model/notification_dto.dart';
import '../constants/app_capabilities.dart';
import '../services/sync_engine.dart';
import '../theme/app_theme.dart';
import '../../features/auth/manager/auth_manager.dart';

final _di = GetIt.instance;

/// Tab definition for the bottom shell navigation.
///
/// [requiredCapability] — if null, the tab is always visible.
/// If set, the tab is shown only when the user's capabilities contain it.
class _ShellTab {
  final IconData icon;
  final String label;
  final String route;
  final String? requiredCapability;

  const _ShellTab({
    required this.icon,
    required this.label,
    required this.route,
    this.requiredCapability,
  });

  /// Ordered list of all shell tabs.
  /// Tabs without [requiredCapability] are always visible.
  /// Tabs with [requiredCapability] are hidden when the user lacks it.
  static const all = [
    _ShellTab(icon: Icons.grid_view, label: 'HOME', route: '/home'),
    _ShellTab(
      icon: Icons.assignment,
      label: 'ACTIVITY',
      route: '/activity',
      requiredCapability: AppCapabilities.submissionsList,
    ),
    _ShellTab(
      icon: Icons.fact_check,
      label: 'PLANS',
      route: '/plans',
      requiredCapability: AppCapabilities.programsList,
    ),
    _ShellTab(
      icon: Icons.description_outlined,
      label: 'TEMPLATES',
      route: '/templates',
      requiredCapability: AppCapabilities.templatesCreate,
    ),
    _ShellTab(icon: Icons.account_circle, label: 'PROFILE', route: '/profile'),
    _ShellTab(icon: Icons.inbox_outlined, label: 'INBOX', route: '/inbox'),
  ];
}

/// Returns the visual active-tab index for [location] given the user's [caps].
///
/// The index is the 0-based position within the *visible* tab list (tabs whose
/// [_ShellTab.requiredCapability] is satisfied by [caps]). This matches what
/// the shell renders and what the user sees highlighted.
///
/// Returns 0 (Home) if no visible tab matches [location].
@visibleForTesting
int shellActiveIndexFromLocation(String location, Set<String> caps) {
  final visible = _ShellTab.all.where((tab) {
    return tab.requiredCapability == null ||
        caps.contains(tab.requiredCapability);
  }).toList();
  final idx = visible.indexWhere((tab) => location.startsWith(tab.route));
  return idx < 0 ? 0 : idx;
}

/// Main shell with dynamic bottom navigation (2–6 tabs based on capabilities).
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
                final visibleTabs = _ShellTab.all.where((tab) {
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
    required _ShellTab tab,
    required bool isActive,
  }) {
    if (tab.route == '/inbox') {
      return ValueListenableBuilder<List<NotificationDto>>(
        valueListenable: _di<NotificationManager>().notifications,
        builder: (context, items, _) {
          final unread = items.where((n) => !n.isRead).length;
          return _NavItem(
            icon: tab.icon,
            label: tab.label,
            isActive: isActive,
            onTap: () => context.go(tab.route),
            badgeCount: unread,
          );
        },
      );
    }

    return _NavItem(
      icon: tab.icon,
      label: tab.label,
      isActive: isActive,
      onTap: () => context.go(tab.route),
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 14,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onError,
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
