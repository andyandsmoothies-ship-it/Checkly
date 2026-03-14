import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Warm-palette filter chip with count badge.
///
/// Deduplicates the identical `_FilterChip` pattern found in:
/// - history_page.dart
/// - action_plans_page.dart
/// - template_list_page.dart
///
/// ```dart
/// WarmChip(
///   label: 'Published',
///   count: 12,
///   selected: _filter == 'published',
///   onTap: () => setState(() => _filter = 'published'),
/// )
/// ```
class WarmChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const WarmChip({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : AppColors.oatmeal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
