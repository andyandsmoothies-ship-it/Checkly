import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_manager.dart';
import '../manager/bod_analytics_data.dart';
import 'bod_ap_bucket_detail_sheet.dart';

/// Renders the action plan aging funnel.
///
/// Includes visual speedometer pill showing Average Resolution time in days,
/// and clickable bucket boxes triggering detailed drill-down modal bottom sheets.
class BodApAgingFunnel extends StatelessWidget {
  final Map<String, dynamic> apAging;
  final double avgTtrDays;
  final BodAnalyticsManager manager;

  const BodApAgingFunnel({
    super.key,
    required this.apAging,
    required this.avgTtrDays,
    required this.manager,
  });

  void _openBucketDetails(BuildContext context, BodAgingBucket bucket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BodApBucketDetailSheet(bucket: bucket, manager: manager),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic aging categories
    final age7 = apAging['0-7'] ?? apAging['0-7 Days'] ?? 10;
    final age30 = apAging['8-30'] ?? apAging['8-30 Days'] ?? 5;
    final age90 = apAging['31-90'] ?? apAging['31-90 Days'] ?? 2;
    final ageOver = apAging['90+'] ?? apAging['90+ Days'] ?? 1;

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap with individual siblings to prevent narrow viewport overflows
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.access_time,
                color: AppColors.cardinal,
                size: 24,
              ),
              Text(
                'Action Plan Aging',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: PillChip(
                  label: 'Avg TTR: ${avgTtrDays.toStringAsFixed(1)} Days',
                  type: avgTtrDays <= 7.0
                      ? PillChipType.green
                      : PillChipType.red,
                  icon: const Icon(
                    Icons.speed,
                    size: 16,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openBucketDetails(context, BodAgingBucket.sevenDays),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildAgingBox(
                    context,
                    '0-7 Days',
                    '$age7',
                    AppColors.iguana.withValues(alpha: 0.15),
                    AppColors.iguana,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _openBucketDetails(context, BodAgingBucket.thirtyDays),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildAgingBox(
                    context,
                    '8-30 Days',
                    '$age30',
                    AppColors.canary.withValues(alpha: 0.2),
                    AppColors.fox,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _openBucketDetails(context, BodAgingBucket.ninetyDays),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildAgingBox(
                    context,
                    '31-90 Days',
                    '$age90',
                    AppColors.flamingo.withValues(alpha: 0.15),
                    AppColors.flamingo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _openBucketDetails(context, BodAgingBucket.overdue),
                  borderRadius: BorderRadius.circular(12),
                  child: _buildAgingBox(
                    context,
                    '90+ Days',
                    '$ageOver',
                    AppColors.cardinal.withValues(alpha: 0.15),
                    AppColors.cardinal,
                  ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.eel,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
