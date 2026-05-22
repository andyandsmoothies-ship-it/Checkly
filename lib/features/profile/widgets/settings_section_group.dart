import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
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

/// SettingsSectionGroup refactored to use [StrokeCard] with zero padding,
/// brand pastel indicators, and Nunito display fonts.
class SettingsSectionGroup extends StatelessWidget {
  final List<MenuItemData> items;
  final bool themeToggle;
  final String? sectionLabel;

  const SettingsSectionGroup({
    super.key,
    required this.items,
    this.themeToggle = false,
    this.sectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = items.isNotEmpty || themeToggle;
    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionLabel != null) _SectionLabel(label: sectionLabel!),
        StrokeCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _MenuTile(data: items[i]),
                if (i < items.length - 1 || themeToggle)
                  const Divider(height: 1, indent: 56, color: AppColors.swan),
              ],
              if (themeToggle) const ThemeToggleTile(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuItemData data;

  const _MenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(data.icon, color: AppColors.featherGreen),
      title: Text(
        data.label,
        style: AppFonts.displayStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.eel,
        ),
      ),
      subtitle: Text(
        data.description,
        style: AppFonts.displayStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.wolf,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.hare),
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

/// Renders a small-caps section label above a [SettingsSectionGroup] card.
/// Font: labelSmall, letterSpacing 1.5, fontWeight w600, primary color.
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.displayStyle(
          fontSize: 11,
          color: AppColors.wolf,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
