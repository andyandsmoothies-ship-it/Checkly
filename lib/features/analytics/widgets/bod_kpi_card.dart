import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';

/// Renders a premium styled KPI Card for the executive analytics dashboard.
class BodKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? description;
  final Widget? rightIndicator;
  final Widget? footer;
  final bool isAlert;
  final VoidCallback? onTap;

  const BodKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.description,
    this.rightIndicator,
    this.footer,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.polar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.swan, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.wolf,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.wolf.withValues(alpha: 0.6),
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isAlert ? AppColors.cardinal : AppColors.eel,
                    ),
                  ),
                ),
              ),
              if (rightIndicator != null) ...[
                const SizedBox(width: 4),
                rightIndicator!,
              ],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 4), footer!],
        ],
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92),
      child: cardContent,
    );
  }
}
