import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../auth/manager/auth_manager.dart';
import '../../../_shared/theme/theme_manager.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';

final _di = GetIt.instance;

/// Profile page — role-aware menu, stats, theme toggle, sign out.
/// Matches PWA Profile spec (§6 research doc).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = _di<AuthManager>();
    final user = auth.currentUser;

    final email = user?.email ?? 'user@checkly.app';
    final role = user?.role ?? 'auditor';
    final initials = _getInitials(email);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ──
          _ProfileCard(initials: initials, email: email, role: role),
          const SizedBox(height: 24),

          // ── Stats Row ──
          _StatsRow(role: role),
          const SizedBox(height: 24),

          // ── Menu Items ──
          ..._buildMenuItems(context, role),
          const SizedBox(height: 24),

          // ── Theme Toggle ──
          _ThemeToggle(),
          const SizedBox(height: 24),

          // ── Sign Out ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('SIGN OUT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Version ──
          Center(
            child: Text(
              'Checkly v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getInitials(String email) {
    final local = email.split('@').first;
    if (local.length >= 2) return local.substring(0, 2).toUpperCase();
    return local.toUpperCase();
  }

  List<Widget> _buildMenuItems(BuildContext context, String role) {
    final items = <_MenuItem>[];

    // Role-conditional items
    if (role == 'admin') {
      items.add(
        const _MenuItem(
          icon: Icons.admin_panel_settings,
          label: 'Admin Dashboard',
          description: 'Manage users and approvals',
          route: '/admin/dashboard',
        ),
      );
    }
    if (role == 'area_manager') {
      items.add(
        const _MenuItem(
          icon: Icons.map_outlined,
          label: 'My Region',
          description: 'View stores in your area',
          route: '/analytics',
        ),
      );
    }
    if (role == 'store_manager') {
      items.add(
        const _MenuItem(
          icon: Icons.store,
          label: 'My Store',
          description: 'View your store details',
          route: '/analytics',
        ),
      );
    }

    // Common items
    items.addAll(const [
      _MenuItem(
        icon: Icons.history,
        label: 'My Activity',
        description: 'View your recent actions',
        route: '/activity',
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        description: 'View all notifications',
        route: '/activity',
      ),
      _MenuItem(
        icon: Icons.menu_book_outlined,
        label: 'Documentation',
        description: 'Guides and user manuals',
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Help',
        description: 'Get support and learn more',
      ),
    ]);

    return items;
  }
}

// ── Profile Card ──

class _ProfileCard extends StatelessWidget {
  final String initials;
  final String email;
  final String role;

  const _ProfileCard({
    required this.initials,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(role, theme);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              email,
              style: AppFonts.serifStyle(
                fontSize: 18,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    );
  }

  Color _roleColor(String role, ThemeData theme) => switch (role) {
    'admin' => Colors.red,
    'auditor' => Colors.blue,
    'store_manager' => Colors.green,
    'area_manager' => Colors.amber.shade700,
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

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  final String role;

  const _StatsRow({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Labels change per role
    final auditLabel = switch (role) {
      'store_manager' => 'Store Audits',
      'area_manager' => 'Region Audits',
      _ => 'My Audits',
    };

    return Row(
      children: [
        Expanded(
          child: _StatColumn(label: auditLabel, value: '—', theme: theme),
        ),
        _divider(theme),
        Expanded(
          child: _StatColumn(label: 'Avg Score', value: '—', theme: theme),
        ),
        _divider(theme),
        Expanded(
          child: _StatColumn(label: 'This Month', value: '—', theme: theme),
        ),
      ],
    );
  }

  Widget _divider(ThemeData theme) => Container(
    width: 1,
    height: 40,
    color: AppTheme.sageGray.withValues(alpha: 0.5),
  );
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Menu Item ──

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String? route;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.description,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.sageGray.withValues(alpha: 0.3)),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          if (route != null) {
            context.push(route!);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Coming soon')));
          }
        },
      ),
    );
  }
}

// ── Theme Toggle ──

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = _di<ThemeManager>();

    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        final isDark = themeManager.themeMode == ThemeMode.dark;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(isDark ? 'Dark mode' : 'Light mode'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeManager.toggleTheme(),
            ),
          ),
        );
      },
    );
  }
}
