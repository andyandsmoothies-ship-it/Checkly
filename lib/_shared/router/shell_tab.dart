import 'package:flutter/material.dart';

import '../constants/app_capabilities.dart';

/// Tab definition for the bottom shell navigation.
///
/// [requiredCapability] — if null, the tab is always visible.
/// If set, the tab is shown only when the user's capabilities contain it.
class ShellTab {
  final IconData icon;
  final String label;
  final String route;
  final String? requiredCapability;

  const ShellTab({
    required this.icon,
    required this.label,
    required this.route,
    this.requiredCapability,
  });

  /// Ordered list of all shell tabs.
  /// Tabs without [requiredCapability] are always visible.
  /// Tabs with [requiredCapability] are hidden when the user lacks the required cap.
  static const all = [
    ShellTab(icon: Icons.grid_view, label: 'HOME', route: '/home'),
    ShellTab(
      icon: Icons.assignment,
      label: 'ACTIVITY',
      route: '/activity',
      requiredCapability: AppCapabilities.submissionsList,
    ),
    ShellTab(icon: Icons.fact_check, label: 'PLANS', route: '/plans'),
    ShellTab(icon: Icons.account_circle, label: 'PROFILE', route: '/profile'),
    ShellTab(icon: Icons.inbox_outlined, label: 'INBOX', route: '/inbox'),
  ];
}

/// SC-4: Extracted from main_shell.dart.
/// Returns the visual active-tab index for [location] given the user's [caps].
///
/// The index is the 0-based position within the *visible* tab list (tabs whose
/// [ShellTab.requiredCapability] is satisfied by [caps]). This matches what
/// the shell renders and what the user sees highlighted.
///
/// Returns 0 (Home) if no visible tab matches [location].
@visibleForTesting
int shellActiveIndexFromLocation(String location, Set<String> caps) {
  final visible = ShellTab.all.where((tab) {
    return tab.requiredCapability == null ||
        caps.contains(tab.requiredCapability);
  }).toList();

  // /templates and /admin/* have no shell tab.
  // Anchor the user on the PROFILE tab to preserve navigation context.
  if (location.startsWith('/templates') || location.startsWith('/admin')) {
    final profileIdx = visible.indexWhere((tab) => tab.route == '/profile');
    return profileIdx < 0 ? 0 : profileIdx;
  }

  final idx = visible.indexWhere((tab) => location.startsWith(tab.route));
  return idx < 0 ? 0 : idx;
}
