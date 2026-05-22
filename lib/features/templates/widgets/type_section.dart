import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

class TypeSection extends StatelessWidget {
  final String label;
  final int count;
  final bool initiallyExpanded;
  final List<Widget> children;

  const TypeSection({
    super.key,
    required this.label,
    required this.count,
    this.initiallyExpanded = true,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.wolf,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.seaSponge,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.turtle, width: 2),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.macaw,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}
