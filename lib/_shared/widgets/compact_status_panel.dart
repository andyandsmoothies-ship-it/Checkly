import 'package:flutter/material.dart';

import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// A core struct for the dense analytical rows.
class StatRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback onTap;

  StatRowData({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.onTap,
  });
}

/// A concise, data-dense status panel that presents KPIs in horizontal rows.
class CompactStatusPanel extends StatelessWidget {
  final List<StatRowData> metrics;

  const CompactStatusPanel({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Card(
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
                  child: InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 20, color: item.iconColor),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                            ),
                          ),
                          Text(
                            item.value,
                            style: Theme.of(context).textTheme.titleMedium?.merge(
                                  AppFonts.serifStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 54,
                    color: AppTheme.sageGray.withValues(alpha: 0.15),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
