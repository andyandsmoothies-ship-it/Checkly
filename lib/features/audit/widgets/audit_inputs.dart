import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/models/template_dto.dart';

// ============================================================
// Input widgets
// ============================================================

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
              color: value == 'conform' ? Colors.white : theme.colorScheme.onSurface,
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
              color: value == 'non_conform' ? Colors.white : theme.colorScheme.onSurface,
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
      return (meta['options'] as List?)?.cast<String>() ?? [];
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
      return (meta['options'] as List?)?.cast<String>() ?? [];
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

class AuditNumericInput extends StatefulWidget {
  final String label;
  final double? value;
  final Color? activeColor;
  final ValueChanged<double> onChanged;

  const AuditNumericInput({
    super.key,
    this.label = 'Faults:',
    this.value,
    this.activeColor,
    required this.onChanged,
  });

  @override
  State<AuditNumericInput> createState() => _AuditNumericInputState();
}

class _AuditNumericInputState extends State<AuditNumericInput> {
  late double _count;

  @override
  void initState() {
    super.initState();
    _count = widget.value ?? 0;
  }

  @override
  void didUpdateWidget(AuditNumericInput old) {
    super.didUpdateWidget(old);
    _count = widget.value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _count > 0;
    final textColor = isActive && widget.activeColor != null
        ? widget.activeColor!
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor ?? theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _count > 0
              ? () {
                  setState(() => _count = max(0, _count - 1));
                  widget.onChanged(_count);
                }
              : null,
          icon: const Icon(Icons.remove, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _count.toInt().toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {
            setState(() => _count++);
            widget.onChanged(_count);
          },
          icon: const Icon(Icons.add, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

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
