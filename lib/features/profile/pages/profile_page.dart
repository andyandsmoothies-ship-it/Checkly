import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../auth/manager/auth_manager.dart';
import '../../../_shared/database/dao/outbox_dao.dart';
import '../../../_shared/database/database_service.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/theme_manager.dart';
import '../../../_shared/theme/app_fonts.dart';

final _di = GetIt.instance;

/// Profile page — role-aware sectioned settings, theme toggle, sign out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = _di<AuthManager>();
    final user = auth.currentUser;

    final displayName = user?.fullName ?? user?.email ?? 'user@checkly.app';
    final email = user?.email ?? 'user@checkly.app';
    final role = user?.role ?? 'auditor';
    final initials = getInitials(user?.fullName ?? email);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ── Identity Header (horizontal) ──
          _ProfileHeader(initials: initials, email: displayName, role: role),
          const SizedBox(height: 24),

          // ── Management Section ──
          _SettingsSectionGroup(items: _managementItems(context, role)),
          const SizedBox(height: 12),

          // ── General Section (Activity + Notifications + Theme) ──
          _SettingsSectionGroup(
            items: [
              _MenuItemData(
                icon: Icons.history,
                label: 'My Activity',
                description: 'View your recent actions',
                route: '/activity',
              ),
              _MenuItemData(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                description: 'View all notifications',
                route: '/activity',
              ),
            ],
            themeToggle: true,
          ),
          const SizedBox(height: 12),

          // ── Support Section ──
          _SettingsSectionGroup(
            items: [
              _MenuItemData(
                icon: Icons.menu_book_outlined,
                label: 'Documentation',
                description: 'Guides and user manuals',
              ),
              _MenuItemData(
                icon: Icons.help_outline,
                label: 'Help',
                description: 'Get support and learn more',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Sign Out ──
          _SignOutTile(),
          const SizedBox(height: 16),

          // ── Version ──
          Center(
            child: Text(
              'Checkly v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @visibleForTesting
  String getInitials(String input) {
    if (input.contains('@')) {
      final local = input.split('@').first;
      return local.length >= 2
          ? local.substring(0, 2).toUpperCase()
          : local.toUpperCase();
    }

    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts.first[0] + parts.last[0]).toUpperCase();
    } else if (parts.isNotEmpty && parts.first.isNotEmpty) {
      final name = parts.first;
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    return '??';
  }

  List<_MenuItemData> _managementItems(BuildContext context, String role) {
    final items = <_MenuItemData>[];
    if (role == 'admin') {
      items.add(_MenuItemData(
        icon: Icons.admin_panel_settings,
        label: 'Admin Dashboard',
        description: 'Manage users and approvals',
        route: '/admin/dashboard',
      ));
    }
    if (role == 'area_manager') {
      items.add(_MenuItemData(
        icon: Icons.map_outlined,
        label: 'My Region',
        description: 'View stores in your area',
        route: '/analytics',
      ));
    }
    if (role == 'store_manager') {
      items.add(_MenuItemData(
        icon: Icons.store,
        label: 'My Store',
        description: 'View your store details',
        route: '/analytics',
      ));
    }
    return items;
  }
}

// ── Identity Header (horizontal) ──────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.initials,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(role, theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: AppFonts.serifStyle(
                    fontSize: theme.textTheme.titleSmall?.fontSize ?? 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role, ThemeData theme) => switch (role) {
    'admin' => AppColors.destructive,
    'auditor' => theme.colorScheme.primary,
    'store_manager' => AppColors.success,
    'area_manager' => AppColors.warning,
    _ => theme.colorScheme.primary,
  };

  String _roleLabel(String role) => switch (role) {
    'admin' => 'ADMIN',
    'auditor' => 'AUDITOR',
    'store_manager' => 'STORE MANAGER',
    'area_manager' => 'AREA MANAGER',
    _ => role.toUpperCase(),
  };
}

// ── Sectioned Settings Card ────────────────────────────────────────────────────

class _MenuItemData {
  final IconData icon;
  final String label;
  final String description;
  final String? route;

  _MenuItemData({
    required this.icon,
    required this.label,
    required this.description,
    this.route,
  });
}

class _SettingsSectionGroup extends StatelessWidget {
  final List<_MenuItemData> items;
  final bool themeToggle;

  const _SettingsSectionGroup({
    required this.items,
    this.themeToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = items.isNotEmpty || themeToggle;
    if (!hasContent) return const SizedBox.shrink();

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(data: items[i]),
            if (i < items.length - 1 || themeToggle)
              Divider(
                height: 1,
                indent: 56,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
          if (themeToggle) _ThemeToggleTile(),
        ],
      ),
    );
  }
}

// ── Individual Menu Tile ───────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final _MenuItemData data;

  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(data.icon, color: theme.colorScheme.primary),
      title: Text(data.label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        data.description,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () {
        HapticFeedback.lightImpact();
        if (data.route != null) {
          context.push(data.route!);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Coming soon')));
        }
      },
    );
  }
}

// ── Theme Toggle Tile (embedded in General section) ────────────────────────────

class _ThemeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = _di<ThemeManager>();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        final isDark = themeManager.themeMode == ThemeMode.dark;
        return ListTile(
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Theme', style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(isDark ? 'Dark mode' : 'Light mode'),
          trailing: Switch(
            value: isDark,
            onChanged: (_) {
              HapticFeedback.lightImpact();
              themeManager.toggleTheme();
            },
          ),
        );
      },
    );
  }
}

// ── Sign Out Tile ──────────────────────────────────────────────────────────────

class _SignOutTile extends StatefulWidget {
  @override
  State<_SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends State<_SignOutTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        'SIGN OUT',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _confirmSignOut(context),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final outbox = OutboxDao(_di<DatabaseService>().db);

    // Check both counts in parallel
    final results = await Future.wait([
      outbox.syncableCount(),
      outbox.exhaustedCount(),
    ]);
    final syncable = results[0];
    final exhausted = results[1];

    if (!context.mounted) return;

    // Case 1: Recoverable submissions in-flight — warn but allow escape.
    if (syncable > 0) {
      final shouldForce = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Audits Still Uploading'),
          content: Text(
            'You have $syncable audit${syncable == 1 ? '' : 's'} still uploading. '
            'Signing out now will permanently delete ${syncable == 1 ? 'it' : 'them'} from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Wait'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Sign Out Anyway',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldForce == true) {
        _di<AuthManager>().logout();
      }
      return;
    }

    // Case 2: Only exhausted (permanently failed) rows remain — warn + allow escape.
    if (exhausted > 0) {
      final shouldForce = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Unsynced Audits Will Be Lost'),
          content: Text(
            '$exhausted audit${exhausted == 1 ? '' : 's'} failed to upload and '
            'cannot be recovered. Signing out will permanently delete '
            '${exhausted == 1 ? 'it' : 'them'} from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Sign Out Anyway',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldForce == true) {
        _di<AuthManager>().logout();
      }
      return;
    }

    // Case 3: Outbox is clean — standard confirmation.
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _di<AuthManager>().logout(),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
