import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

/// A compact KPI summary card used in [ProgramDashboardPage].
///
/// Displays an icon, a large numeric value, and a label below it.
/// Uses [Expanded] so it fills its parent flex row evenly.
class ProgramKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const ProgramKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.displayStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
