import 'package:flutter/material.dart';
import '../../../../_shared/widgets/primitives/pill_chip.dart';

class TypeBadge extends StatelessWidget {
  final String type;

  const TypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final t = type.toLowerCase();
    PillChipType chipType;

    if (t == 'qc') {
      chipType = PillChipType.green;
    } else if (t == 'training') {
      chipType = PillChipType.blue;
    } else if (t == 'general') {
      chipType = PillChipType.purple;
    } else {
      chipType = PillChipType.yellow;
    }

    return PillChip(label: type.toUpperCase(), type: chipType);
  }
}
