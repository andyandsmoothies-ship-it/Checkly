import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../auth/manager/auth_manager.dart';
import '../../../_shared/constants/user_persona.dart';
import '../widgets/sign_out_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_section_group.dart';
import '../widgets/profile_capabilities_section.dart';

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
    final persona = UserPersona.fromRole(user?.role);
    final initials = getInitials(user?.fullName ?? email);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ── Identity Header (horizontal) ──
          ProfileHeader(initials: initials, email: displayName, role: role),
          const SizedBox(height: 24),

          // ── Management Section ──
          SettingsSectionGroup(items: _managementItems(context, persona)),
          const SizedBox(height: 12),

          // ── General Section (Activity + Notifications + Theme) ──
          SettingsSectionGroup(
            items: [
              MenuItemData(
                icon: Icons.history,
                label: 'My Activity',
                description: 'View your recent actions',
                route: '/activity',
              ),
              MenuItemData(
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
          SettingsSectionGroup(
            items: [
              MenuItemData(
                icon: Icons.menu_book_outlined,
                label: 'Documentation',
                description: 'Guides and user manuals',
              ),
              MenuItemData(
                icon: Icons.help_outline,
                label: 'Help',
                description: 'Get support and learn more',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── PBAC Capabilities Section ──
          const ProfileCapabilitiesSection(),
          const SizedBox(height: 24),

          // ── Sign Out ──
          const SignOutTile(),
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

  List<MenuItemData> _managementItems(
    BuildContext context,
    UserPersona persona,
  ) {
    final items = <MenuItemData>[];
    if (persona == UserPersona.admin) {
      items.add(
        MenuItemData(
          icon: Icons.admin_panel_settings,
          label: 'Admin Dashboard',
          description: 'Manage users and approvals',
          route: '/admin/dashboard',
        ),
      );
    }
    if (persona == UserPersona.areaManager) {
      items.add(
        MenuItemData(
          icon: Icons.map_outlined,
          label: 'My Region',
          description: 'View stores in your area',
          route: '/analytics',
        ),
      );
    }
    if (persona == UserPersona.storeManager) {
      items.add(
        MenuItemData(
          icon: Icons.store,
          label: 'My Store',
          description: 'View your store details',
          route: '/analytics',
        ),
      );
    }
    return items;
  }
}
