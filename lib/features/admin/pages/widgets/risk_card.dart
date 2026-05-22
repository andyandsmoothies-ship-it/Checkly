import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

/// Card widget representing a critical operational risk.
/// Refactored to utilize the [UniversalListCard] primitive.
class RiskCard extends StatelessWidget {
  final Map<String, dynamic> risk;
  final VoidCallback? onTap;

  const RiskCard({super.key, required this.risk, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = risk['label'] as String? ?? 'Unnamed';
    final description = risk['description'] as String? ?? '';
    final isActive = risk['isActive'] as bool? ?? true;

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.warning.withAlpha(25)
              : theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield_outlined,
          color: isActive
              ? AppTheme.warning
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: label,
      subtitle: description.isNotEmpty ? description : null,
      badges: [
        if (!isActive)
          const PillChip(label: 'Inactive', type: PillChipType.red),
      ],
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
          : null,
    );
  }
}
