import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';
import '../manager/area_bod_manager.dart';
import '../manager/bod_analytics_data.dart' show BodAgingBucket;
import 'area_bod_ap_bucket_detail_sheet.dart';

/// KPI Grid component displaying Area performance insights.
class AreaBodKpiGrid extends StatelessWidget {
  final AreaBodKpis kpis;
  final List<AreaTrendPoint> trend;
  final AreaGoldenStore? goldenStore;
  final AreaBodManager manager;

  const AreaBodKpiGrid({
    super.key,
    required this.kpis,
    required this.trend,
    required this.manager,
    this.goldenStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    final totalAudits = kpis.totalAudits;
    final avgScore = kpis.avgScore;
    final completionRate = kpis.completionRate;
    final openAPs = kpis.openActionPlans;
    final overdueAPs = kpis.overdueActionPlans;
    final activeStores = kpis.activeStores;
    final totalAuditors = kpis.totalAuditors;

    final double rawAvgTtrDays = kpis.avgTtrDays;
    final String avgTtrDisplay = rawAvgTtrDays <= 0.0
        ? 'N/A'
        : '${rawAvgTtrDays.toStringAsFixed(1)} days';

    PillChip? avgTtrPill;
    if (rawAvgTtrDays > 0.0) {
      if (rawAvgTtrDays <= 7.0) {
        avgTtrPill = const PillChip(label: 'Fast', type: PillChipType.green);
      } else if (rawAvgTtrDays <= 14.0) {
        avgTtrPill = const PillChip(
          label: 'On Pace',
          type: PillChipType.yellow,
        );
      } else {
        avgTtrPill = const PillChip(label: 'Slow', type: PillChipType.red);
      }
    }

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights,
                color: AppColors.featherGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Area Performance KPIs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Average Score',
                      '${avgScore.toStringAsFixed(1)}%',
                      description: 'Average score of finished audits',
                      footer: goldenStore != null && goldenStore!.avgScore > 0
                          ? Text(
                              '${((avgScore / goldenStore!.avgScore) * 100).toStringAsFixed(0)}% of flagship (${goldenStore!.storeName} ${goldenStore!.avgScore.toStringAsFixed(1)}%)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subTextCol,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Completion Rate',
                      '${completionRate.toStringAsFixed(1)}%',
                      description: 'Planned vs finished audits ratio',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Avg TTR Days',
                      avgTtrDisplay,
                      description: 'Average days to resolve an action plan',
                      rightIndicator: avgTtrPill,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Overdue / Open APs',
                      '$overdueAPs / $openAPs',
                      description: 'Late Action Plans / Active Action Plans',
                      isAlert: overdueAPs > 0,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AreaBodApBucketDetailSheet(
                            bucket: BodAgingBucket.all,
                            manager: manager,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Total Audits',
                      '$totalAudits',
                      description: 'Total finished audits in last 30 days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Active Stores',
                      '$activeStores',
                      description: 'Stores with audit activity in last 30 days',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Total Auditors',
                      '$totalAuditors',
                      description: 'Unique auditors submitting audits',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String label,
    String value, {
    String? description,
    Widget? rightIndicator,
    Widget? footer,
    bool isAlert = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgCol = isLight ? AppColors.polar : AppColors.eel;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? AppColors.swan
              : AppColors.swan.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextCol,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subTextCol.withValues(alpha: 0.7),
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
                      color: isAlert ? AppColors.cardinal : textCol,
                    ),
                  ),
                ),
              ),
              if (rightIndicator != null) ...[
                const SizedBox(width: 4),
                rightIndicator,
              ],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 4), footer],
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
