import 'dart:math';

import 'package:flutter/material.dart';

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
