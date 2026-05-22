import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Warm-palette filter chip with count badge.
///
/// Deduplicates the identical `_FilterChip` pattern found in:
/// - history_page.dart
/// - action_plans_page.dart
/// - template_list_page.dart
///
/// Refactored to use a bubbly selected style (FeatherGreen fill + Snow text)
/// and a flat Swan-bordered unselected style.
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
    final text = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.eel,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
