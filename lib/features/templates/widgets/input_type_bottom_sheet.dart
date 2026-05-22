import 'package:flutter/material.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

/// Lookup helpers for input type display.
IconData inputTypeIcon(String type) => switch (type) {
  'pass_fail' => Icons.check_circle_outline,
  'numeric' => Icons.pin_outlined,
  'scale' => Icons.linear_scale,
  'single_choice' => Icons.radio_button_checked,
  'multi_choice' => Icons.checklist,
  'text' => Icons.text_fields,
  _ => Icons.help_outline,
};

String inputTypeLabel(String type) => switch (type) {
  'pass_fail' => 'Pass / Fail',
  'numeric' => 'Fault Count',
  'scale' => 'Scored Choices',
  'single_choice' => 'Single Choice',
  'multi_choice' => 'Multi Choice',
  'text' => 'Text Input',
  _ => type,
};

class InputTypeBottomSheet extends StatelessWidget {
  final String currentType;
  final String? scoringMode; // optional — null means no constraint

  const InputTypeBottomSheet({
    super.key,
    required this.currentType,
    this.scoringMode,
  });

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
    (
      value: 'text',
      icon: Icons.text_fields,
      title: 'Text Input',
      desc: 'Free-form text answer (notes, observations).',
      helper: 'Used for data collection ONLY. Does not affect the score.',
    ),
  ];

  /// Returns true when [inputType] is not valid for [scoringMode].
  /// This is an ALLOWLIST: only explicitly listed modes constrain types.
  /// Unknown or null modes allow all types (backward-compatible default).
  static bool _isDisabledForMode(String inputType, String? scoringMode) =>
      switch (scoringMode) {
        'survey' =>
          inputType == 'pass_fail' ||
              inputType == 'numeric' ||
              inputType == 'scale',
        'checklist' => inputType == 'numeric' || inputType == 'scale',
        _ => false,
      };

  /// Human-readable label for the disabled subtitle line.
  static String _modeLabel(String? scoringMode) => switch (scoringMode) {
    'survey' => 'Survey',
    'checklist' => 'Checklist',
    _ => '',
  };

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
                  final isDisabled = _isDisabledForMode(t.value, scoringMode);

                  return Opacity(
                    opacity: isDisabled ? 0.45 : 1.0,
                    child: StrokeCard(
                      margin: EdgeInsets.zero,
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.4,
                            )
                          : null,
                      borderColor: isSelected
                          ? theme.colorScheme.primary
                          : null,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onTap: isDisabled
                          ? null
                          : () => Navigator.pop(context, t.value),
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
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  isDisabled
                                      ? 'Not available in ${_modeLabel(scoringMode)} mode.'
                                      : t.helper,
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
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                        ],
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
