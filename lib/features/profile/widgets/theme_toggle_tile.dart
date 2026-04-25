import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/theme_manager.dart';

final _di = GetIt.instance;

/// Theme toggle tile — shown in the General settings section.
class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

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
          title: const Text(
            'Theme',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
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
