import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';

/// Inline editor for single_choice / multi_choice criterion options.
///
/// Renders a labelled text field for each choice option,
/// with add/remove controls. Mutations are applied directly
/// to [criterion] (mutable reference); [onChanged] marks the
/// parent dirty and [onRequestRebuild] re-opens the drawer
/// to reflect structural changes (add / remove rows).
class CriterionChoiceEditor extends StatelessWidget {
  final EditableCriterion criterion;
  final VoidCallback onChanged;
  final VoidCallback onRequestRebuild;

  const CriterionChoiceEditor({
    super.key,
    required this.criterion,
    required this.onChanged,
    required this.onRequestRebuild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choice Options',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: theme.textTheme.bodyMedium?.fontSize,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'List the specific options the auditor can select from',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...criterion.choiceOptions.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: label,
                    decoration: InputDecoration(
                      labelText: 'Option ${idx + 1}',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      criterion.choiceOptions[idx] = v;
                      onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    criterion.choiceOptions.removeAt(idx);
                    onChanged();
                    onRequestRebuild();
                  },
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            criterion.choiceOptions.add('');
            onChanged();
            onRequestRebuild();
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Option'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
