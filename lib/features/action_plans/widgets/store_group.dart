import 'package:flutter/material.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../model/action_plan_dto.dart';
import 'action_plan_card.dart';

class StoreGroup extends StatelessWidget {
  final String storeName;
  final List<ActionPlanDto> plans;
  final ValueChanged<ActionPlanDto> onTap;

  const StoreGroup({
    super.key,
    required this.storeName,
    required this.plans,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              storeName.toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                fontWeight: FontWeight.w700,
                // WCAG: raised from 0.4 → 0.85 for clear section header hierarchy
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${plans.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: plans
            .map(
              (plan) => ActionPlanCard(plan: plan, onTap: () => onTap(plan)),
            )
            .toList(),
      ),
    );
  }
}
