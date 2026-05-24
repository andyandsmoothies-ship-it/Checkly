import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodApAgingFunnel extends StatelessWidget {
  final Map<String, dynamic> apAging;

  const BodApAgingFunnel({super.key, required this.apAging});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic aging categories
    final age30 = apAging['0-30'] ?? apAging['0-30 Days'] ?? 10;
    final age60 = apAging['31-60'] ?? apAging['31-60 Days'] ?? 5;
    final age90 = apAging['61-90'] ?? apAging['61-90 Days'] ?? 2;
    final ageOver = apAging['90+'] ?? apAging['90+ Days'] ?? 1;

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.cardinal, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Action Plan Aging',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAgingBox(
                  context,
                  '0-30 Days',
                  '$age30',
                  AppColors.iguana.withValues(alpha: 0.15),
                  AppColors.iguana,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAgingBox(
                  context,
                  '31-60 Days',
                  '$age60',
                  AppColors.canary.withValues(alpha: 0.2),
                  AppColors.fox,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAgingBox(
                  context,
                  '61-90 Days',
                  '$age90',
                  AppColors.flamingo.withValues(alpha: 0.15),
                  AppColors.flamingo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAgingBox(
                  context,
                  '90+ Days',
                  '$ageOver',
                  AppColors.cardinal.withValues(alpha: 0.15),
                  AppColors.cardinal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingBox(
    BuildContext context,
    String label,
    String count,
    Color bgColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.eel,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
