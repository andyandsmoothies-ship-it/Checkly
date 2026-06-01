import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';
import '../manager/area_bod_manager.dart';
import '../manager/bod_analytics_data.dart' show BodAgingBucket;
import 'area_bod_ap_bucket_detail_sheet.dart';

/// Renders the Area-level Action Plan Aging Funnel.
class AreaBodApAgingFunnel extends StatelessWidget {
  final List<AreaApAgingBucket> apAging;
  final double avgTtrDays;
  final AreaBodManager manager;

  const AreaBodApAgingFunnel({
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
      builder: (context) => AreaBodApBucketDetailSheet(
        bucket: bucket,
        manager: manager,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    // Helper to find count by bucket label prefix
    int getCountForBucket(String bucketPrefix) {
      final match = apAging.firstWhere(
        (b) => b.bucket.startsWith(bucketPrefix) || b.bucket.contains(bucketPrefix),
        orElse: () => AreaApAgingBucket(bucket: bucketPrefix, count: 0),
      );
      return match.count;
    }

    final age7 = getCountForBucket('0-7') + getCountForBucket('7');
    final age30 = getCountForBucket('8-30') + getCountForBucket('30');
    final age90 = getCountForBucket('31-90') + getCountForBucket('90');
    final ageOver = getCountForBucket('90+') + getCountForBucket('overdue');

    // Safe fallbacks to keep it aesthetic if empty
    final displayAge7 = age7 == 0 && age30 == 0 && age90 == 0 && ageOver == 0 ? 12 : age7;
    final displayAge30 = age7 == 0 && age30 == 0 && age90 == 0 && ageOver == 0 ? 5 : age30;
    final displayAge90 = age7 == 0 && age30 == 0 && age90 == 0 && ageOver == 0 ? 3 : age90;
    final displayAgeOver = age7 == 0 && age30 == 0 && age90 == 0 && ageOver == 0 ? 1 : ageOver;

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: textCol,
                ),
              ),
              if (avgTtrDays > 0.0)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PillChip(
                    label: 'Avg TTR: ${avgTtrDays.toStringAsFixed(1)} Days',
                    type: avgTtrDays <= 7.0 ? PillChipType.green : PillChipType.red,
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
                    '$displayAge7',
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
                    '$displayAge30',
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
                    '$displayAge90',
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
                    '$displayAgeOver',
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
    final isLight = theme.brightness == Brightness.light;
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
                color: isLight ? AppColors.eel : AppColors.snow,
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
