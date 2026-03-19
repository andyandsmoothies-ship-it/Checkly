import 'package:flutter/material.dart';

/// Lookup helpers for input type display.
IconData inputTypeIcon(String type) => switch (type) {
  'pass_fail' => Icons.check_circle_outline,
  'numeric' => Icons.pin_outlined,
  'scale' => Icons.linear_scale,
  'single_choice' => Icons.radio_button_checked,
  'multi_choice' => Icons.checklist,
  _ => Icons.help_outline,
};

String inputTypeLabel(String type) => switch (type) {
  'pass_fail' => 'Pass / Fail',
  'numeric' => 'Fault Count',
  'scale' => 'Scored Choices',
  'single_choice' => 'Single Choice',
  'multi_choice' => 'Multi Choice',
  _ => type,
};

class InputTypeBottomSheet extends StatelessWidget {
  final String currentType;

  const InputTypeBottomSheet({super.key, required this.currentType});

  static const _types = [
    (
      value: 'pass_fail',
      icon: Icons.check_circle_outline,
      title: 'Pass / Fail',
      desc: 'Binary check — e.g., "Is the floor clean?"',
      helper:
          'Auditor taps Pass or Fail. Fails trigger point deductions based on your scoring rules.',
    ),
    (
      value: 'numeric',
      icon: Icons.pin_outlined,
      title: 'Fault Count',
      desc: 'Count occurrences — e.g., "How many expired items?"',
      helper:
          'Auditor enters a number. Each fault multiplies the deduction rate you configure.',
    ),
    (
      value: 'scale',
      icon: Icons.linear_scale,
      title: 'Scored Choices',
      desc: 'Maturity scale — e.g., Poor / Fair / Good / Excellent',
      helper:
          'Auditor picks one option from a scored list. You assign different point values to each level.',
    ),
    (
      value: 'single_choice',
      icon: Icons.radio_button_checked,
      title: 'Single Choice',
      desc: 'Pick one — e.g., "Which shift?"',
      helper:
          'Auditor selects one option. No scoring impact — used for data collection and filtering.',
    ),
    (
      value: 'multi_choice',
      icon: Icons.checklist,
      title: 'Multi Choice',
      desc: 'Pick many — e.g., "Select all that apply"',
      helper:
          'Auditor selects multiple options. No scoring impact — used for multi-tag data collection.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Input Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _types.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final isSelected = t.value == currentType;

                  return Card(
                    elevation: 0,
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            )
                          : BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, t.value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              t.icon,
                              size: 22,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    t.desc,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      t.helper,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
