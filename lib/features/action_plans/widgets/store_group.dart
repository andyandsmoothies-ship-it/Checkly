import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
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
                '${plans.length}',
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
        children: plans
            .map((plan) => ActionPlanCard(plan: plan, onTap: () => onTap(plan)))
            .toList(),
      ),
    );
  }
}
