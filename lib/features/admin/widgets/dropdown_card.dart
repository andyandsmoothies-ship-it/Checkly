import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

class DropdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const DropdownCard({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppFonts.displayStyle(
                    fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: value,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}
