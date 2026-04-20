import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'theme_toggle_tile.dart';

class MenuItemData {
  final IconData icon;
  final String label;
  final String description;
  final String? route;

  MenuItemData({
    required this.icon,
    required this.label,
    required this.description,
    this.route,
  });
}

class SettingsSectionGroup extends StatelessWidget {
  final List<MenuItemData> items;
  final bool themeToggle;

  const SettingsSectionGroup({
    super.key,
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
          if (themeToggle) const ThemeToggleTile(),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuItemData data;

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
