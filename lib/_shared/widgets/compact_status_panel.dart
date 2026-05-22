import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/primitives/primitives.dart';

/// A core struct for the dense analytical rows.
class StatRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  StatRowData({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
  });
}

/// A concise, data-dense status panel that presents KPIs in horizontal rows.
///
/// Refactored to use [StrokeCard] and [AppColors.swan] dividers for gamified aesthetic.
class CompactStatusPanel extends StatelessWidget {
  final List<StatRowData> metrics;

  const CompactStatusPanel({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return StrokeCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: metrics.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == metrics.length - 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: _buildRow(context, item),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 54,
                    color: AppColors.swan,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds the inner row for a single metric.
  /// When [item.onTap] is null the row is informational-only:
  /// - no ripple / InkWell gesture
  /// - no trailing chevron icon
  Widget _buildRow(BuildContext context, StatRowData item) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: item.iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            item.value,
            style: AppFonts.displayStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.eel,
            ),
          ),
          if (item.onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.hare),
          ],
        ],
      ),
    );

    if (item.onTap == null) return content;
    return InkWell(onTap: item.onTap, child: content);
  }
}
