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
      desc: 'Binary compliance check.',
      helper: 'Auditor selects Pass or Fail. Fails deduct points.',
    ),
    (
      value: 'numeric',
      icon: Icons.pin_outlined,
      title: 'Fault Count',
      desc: 'Defect counter (e.g., number of expired items).',
      helper: 'Auditor enters a number. Deducts points per fault.',
    ),
    (
      value: 'scale',
      icon: Icons.linear_scale,
      title: 'Scored Choices',
      desc: 'Maturity scale (e.g., Poor, Fair, Good).',
      helper: 'Each choice awards or deducts a specific point value.',
    ),
    (
      value: 'single_choice',
      icon: Icons.radio_button_checked,
      title: 'Single Choice',
      desc: 'Pick exactly one option from a custom list.',
      helper: 'Used for data collection ONLY. Does not affect the score.',
    ),
    (
      value: 'multi_choice',
      icon: Icons.checklist,
      title: 'Multi Choice',
      desc: 'Pick multiple options from a custom list.',
      helper: 'Used for data collection ONLY. Does not affect the score.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Give bottom sheet more max height if needed, but defaults are fine
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
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final isSelected = t.value == currentType;

                  return Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
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
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                t.icon,
                                size: 24,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.desc,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.helper,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 2,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
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
