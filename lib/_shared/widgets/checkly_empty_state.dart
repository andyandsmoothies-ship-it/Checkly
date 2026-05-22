import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Standardized empty state widget used across Checkly.
///
/// Optionally accepts an [actionButton] widget (e.g. an ElevatedButton)
/// rendered below the subtitle as a call-to-action.
///
/// Refactored to use [AppColors.polar] background and bold Nunito labels.
class ChecklyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? actionButton;
  final String? emoji;

  const ChecklyEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.subtitle,
    this.actionButton,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.polar,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.swan, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 56))
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.seaSponge,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.turtle, width: 2),
                  ),
                  child: Icon(icon, size: 36, color: AppColors.featherGreen),
                ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.wolf,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 24),
                actionButton!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
