import 'package:flutter/material.dart';
import '../../../../_shared/widgets/primitives/pill_chip.dart';

class TypeBadge extends StatelessWidget {
  final String type;

  const TypeBadge({super.key, required this.type});

  String _normalize(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'qc') return 'qc';
    if (t == 'training') return 'training';
    if (t == 'general') return 'general';
    if (t == 'task force' || t == 'task_force' || t == 'taskforce') {
      return 'task force';
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final t = _normalize(type);
    PillChipType chipType;

    if (t == 'qc') {
      chipType = PillChipType.green;
    } else if (t == 'training') {
      chipType = PillChipType.blue;
    } else if (t == 'general') {
      chipType = PillChipType.purple;
    } else if (t == 'task force') {
      chipType = PillChipType.yellow;
    } else {
      chipType = PillChipType.yellow;
    }

    final label = t == 'task force' ? 'TASK FORCE' : t.toUpperCase();
    return PillChip(label: label, type: chipType);
  }
}
