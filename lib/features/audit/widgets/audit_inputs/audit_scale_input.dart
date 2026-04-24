import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../templates/models/template_dto.dart';

// ═══════════════════════════════════════════════════════════════
// SCALE INPUT — gradient maturity selector
// ═══════════════════════════════════════════════════════════════

class AuditScaleInput extends StatelessWidget {
  final CriterionDto criterion;
  final String? selectedValue;
  final void Function(String label, double points) onChanged;

  const AuditScaleInput({
    super.key,
    required this.criterion,
    required this.selectedValue,
    required this.onChanged,
  });

  List<Map<String, dynamic>> _parseOptions() {
    if (criterion.metadata == null) return [];
    try {
      final meta = json.decode(criterion.metadata!) as Map<String, dynamic>;
      return (meta['scaleOptions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _parseOptions();
    final theme = Theme.of(context);

    if (options.isEmpty) {
      return Text(
        'No scale options configured for this criterion.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((opt) {
        final label = opt['label'] as String? ?? '';
        final points = (opt['points'] as num?)?.toDouble() ?? 0;
        final isSelected = selectedValue == label;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(label, points),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${points.toStringAsFixed(0)} pts',
                      style: TextStyle(
                        fontSize: theme.textTheme.bodySmall?.fontSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
