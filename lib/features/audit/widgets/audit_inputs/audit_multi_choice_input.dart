import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../templates/models/template_dto.dart';

class AuditMultiChoiceInput extends StatelessWidget {
  final CriterionDto criterion;
  final String? selectedValues; // comma-separated string
  final ValueChanged<String> onChanged;

  const AuditMultiChoiceInput({
    super.key,
    required this.criterion,
    required this.selectedValues,
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

  Set<String> _parseSelected() {
    if (selectedValues == null || selectedValues!.isEmpty) return {};
    return selectedValues!.split(',').map((s) => s.trim()).toSet();
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
    final selected = _parseSelected();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        return CheckboxListTile(
          title: Text(opt),
          value: selected.contains(opt),
          onChanged: (checked) {
            final updated = Set<String>.from(selected);
            if (checked == true) {
              updated.add(opt);
            } else {
              updated.remove(opt);
            }
            onChanged(updated.join(', '));
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }
}
