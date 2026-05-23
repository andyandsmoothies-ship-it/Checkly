import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'pill_chip.dart';

/// A shared expansion tile group header for grouped list views.
///
/// Renders a store name in gamified uppercase Nunito typography
/// alongside a [PillChip] badge showing the item count.
/// Used by both the Audit (History) and Action Plans screens.
class UniversalStoreGroup extends StatelessWidget {
  final String storeName;
  final int count;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsets tilePadding;

  const UniversalStoreGroup({
    super.key,
    required this.storeName,
    required this.count,
    required this.children,
    this.initiallyExpanded = true,
    this.tilePadding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: tilePadding,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Flexible(
              child: Text(
                storeName.toUpperCase(),
                style: AppFonts.displayStyle(
                  fontSize: theme.textTheme.labelSmall?.fontSize,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  letterSpacing: 3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            PillChip(label: '$count', type: PillChipType.blue),
          ],
        ),
        children: children,
      ),
    );
  }
}
