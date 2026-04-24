import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../templates/models/template_dto.dart';

class AuditSingleChoiceInput extends StatelessWidget {
  final CriterionDto criterion;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  const AuditSingleChoiceInput({
    super.key,
    required this.criterion,
    required this.selectedValue,
    required this.onChanged,
  });

  List<String> _parseOptions() {
    if (criterion.metadata == null) return [];
    try {
      final meta = json.decode(criterion.metadata!) as Map<String, dynamic>;
      final list = meta['options'] as List?;
      if (list == null) return [];

      return list.map((e) {
        if (e is String) return e;
        if (e is Map) return (e['label'] as String?) ?? '';
        return e.toString();
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _parseOptions();
    if (options.isEmpty) {
      return Text(
        'No options configured for this criterion.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final isSelected = selectedValue == opt;
        return InkWell(
          onTap: () => onChanged(opt),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(opt)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
