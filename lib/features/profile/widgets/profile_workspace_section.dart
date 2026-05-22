import 'package:flutter/material.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/constants/user_persona.dart';
import 'admin_command_card.dart';
import 'settings_section_group.dart';

/// MY WORKSPACE zone for the Profile page.
///
/// Renders role-specific workspace tiles gated by [persona] and [caps]:
/// - Admin: Two [AdminCommandCard]s — Admin Dashboard (primary) + Campaigns (tertiary).
///   Templates tile only shown if [AppCapabilities.templatesCreate] is in [caps].
/// - Area Manager: My Region tile.
/// - Store Manager: My Store tile.
/// - Auditor: returns [SizedBox.shrink] — no workspace items (H5 graceful degradation).
///
/// The Templates tile is gated by [caps], NOT by [persona], per PBAC rules.
class ProfileWorkspaceSection extends StatelessWidget {
  final UserPersona persona;
  final Set<String> caps;

  const ProfileWorkspaceSection({
    super.key,
    required this.persona,
    required this.caps,
  });

  @override
  Widget build(BuildContext context) {
    final personaItems = _buildPersonaItems(context);
    final hasTemplates = caps.contains(AppCapabilities.templatesCreate);

    // Auditor: no workspace items — hide the entire section.
    if (persona == UserPersona.auditor && !hasTemplates) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context),
        if (persona == UserPersona.admin)
          _buildAdminWorkspace(context, hasTemplates)
        else
          _buildStandardWorkspace(context, personaItems, hasTemplates),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
      child: Text(
        'MY WORKSPACE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAdminWorkspace(BuildContext context, bool hasTemplates) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const AdminCommandCard(
          icon: Icons.admin_panel_settings,
          title: 'Admin Dashboard',
          subtitle: 'Users · Stores · Approvals · Logs',
          route: '/admin/dashboard',
        ),
        const SizedBox(height: 8),
        AdminCommandCard(
          icon: Icons.campaign_rounded,
          title: 'Campaigns',
          subtitle: 'View and manage audit programmes',
          route: '/programs',
          overrideColor: cs.tertiaryContainer,
          overrideIconColor: cs.tertiary,
          overrideTextColor: cs.onTertiaryContainer,
        ),
        if (hasTemplates) ...[
          const SizedBox(height: 8),
          AdminCommandCard(
            icon: Icons.description_outlined,
            title: 'Templates',
            subtitle: 'Manage audit templates',
            route: '/templates',
            overrideColor: cs.secondaryContainer,
            overrideIconColor: cs.secondary,
            overrideTextColor: cs.onSecondaryContainer,
          ),
        ],
      ],
    );
  }

  Widget _buildStandardWorkspace(
    BuildContext context,
    List<MenuItemData> personaItems,
    bool hasTemplates,
  ) {
    final items = [
      ...personaItems,
      if (hasTemplates)
        MenuItemData(
          icon: Icons.description_outlined,
          label: 'Templates',
          description: 'Manage audit templates',
          route: '/templates',
        ),
    ];
    return SettingsSectionGroup(items: items);
  }

  List<MenuItemData> _buildPersonaItems(BuildContext context) {
    return switch (persona) {
      UserPersona.admin => [],
      UserPersona.areaManager => [
        MenuItemData(
          icon: Icons.map_outlined,
          label: 'My Region',
          description: 'View stores in your area',
          route: '/analytics',
        ),
      ],
      UserPersona.storeManager => [
        MenuItemData(
          icon: Icons.store,
          label: 'My Store',
          description: 'View your store details',
          route: '/analytics',
        ),
      ],
      UserPersona.auditor => [],
    };
  }
}
