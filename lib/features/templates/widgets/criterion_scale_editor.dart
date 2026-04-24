import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';

/// Inline editor for scale-type criterion options.
///
/// Renders label + points rows for each scale option,
/// with add/remove controls. Mutations are applied directly
/// to [criterion] (mutable reference); [onChanged] marks the
/// parent dirty and [onRequestRebuild] re-opens the drawer
/// to reflect structural changes (add / remove rows).
class CriterionScaleEditor extends StatelessWidget {
  final EditableCriterion criterion;
  final VoidCallback onChanged;
  final VoidCallback onRequestRebuild;

  const CriterionScaleEditor({
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
          'Scale Options',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: theme.textTheme.bodyMedium?.fontSize,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Define maturity levels and their respective points (e.g. 1=Poor, 5=Excellent)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...criterion.scaleOptions.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: opt['label'] as String? ?? '',
                    decoration: InputDecoration(
                      labelText: 'Label ${idx + 1}',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      criterion.scaleOptions[idx]['label'] = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue:
                        (opt['points'] as num?)?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Pts',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      criterion.scaleOptions[idx]['points'] =
                          double.tryParse(v) ?? 0;
                      // Auto-sync pointsWeight to highest
                      final maxPts = criterion.scaleOptions.fold<double>(
                        0,
                        (m, o) =>
                            (o['points'] as num? ?? 0).toDouble() > m
                            ? (o['points'] as num).toDouble()
                            : m,
                      );
                      criterion.pointsCtrl.text =
                          maxPts.toStringAsFixed(0);
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
                    criterion.scaleOptions.removeAt(idx);
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
            criterion.scaleOptions.add({'label': '', 'points': 0});
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
