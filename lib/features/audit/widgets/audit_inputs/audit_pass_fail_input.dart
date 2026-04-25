import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';

class AuditPassFailInput extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const AuditPassFailInput({super.key, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Conform')),
            selected: value == 'conform',
            selectedColor: AppTheme.success,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: value == 'conform'
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
            checkmarkColor: Colors.white,
            onSelected: (selected) {
              if (selected) onChanged('conform');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Non-Conform')),
            selected: value == 'non_conform',
            selectedColor: theme.colorScheme.error,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: value == 'non_conform'
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
            checkmarkColor: Colors.white,
            onSelected: (selected) {
              if (selected) onChanged('non_conform');
            },
          ),
        ),
      ],
    );
  }
}
