import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';
import '../manager/bod_analytics_manager.dart';
import 'bod_mom_delta_chip.dart';
import 'bod_ap_bucket_detail_sheet.dart';

/// KPI Grid component displaying executive boardroom chain performance insights.
///
/// Features a flagship benchmark comparison to the highest-performing global store
/// and Month-over-Month trend delta pill chips.
class BodKpiGrid extends StatelessWidget {
  final Map<String, dynamic> chainKpis;
  final List<dynamic> trend;
  final BodGoldenStore? goldenStore;
  final BodAnalyticsManager manager;

  const BodKpiGrid({
    super.key,
    required this.chainKpis,
    required this.trend,
    required this.manager,
    this.goldenStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalAudits = chainKpis['totalAudits'] ?? 0;
    final avgScore = chainKpis['avgScore']?.toDouble() ?? 0.0;
    final completionRate = chainKpis['completionRate']?.toDouble() ?? 0.0;
    final completionRateDelta =
        chainKpis['completionRateDelta']?.toDouble() ?? 0.0;
    final openAPs = chainKpis['openAPs'] ?? 0;
    final overdueAPs = chainKpis['overdueAPs'] ?? 0;
    final activeStores = chainKpis['activeStores'] ?? 0;
    final totalAuditors = chainKpis['totalAuditors'] ?? 0;

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
                  'Chain Performance KPIs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
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
                      description: 'Average score of finished audits (last 30 days)',
                      rightIndicator: BodMomDeltaChip(trend: trend),
                      footer: goldenStore != null
                          ? Text(
                              '${((avgScore / goldenStore!.avgScore) * 100).toStringAsFixed(0)}% of flagship (${goldenStore!.storeName} ${goldenStore!.avgScore.toStringAsFixed(1)}%)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.wolf,
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
                      description: 'How many planned audits were actually finished (last 30 days)',
                      rightIndicator: completionRateDelta != 0.0
                          ? PillChip(
                              label:
                                  '${completionRateDelta >= 0.0 ? "↑" : "↓"} ${completionRateDelta.abs().toStringAsFixed(1)}%',
                              type: completionRateDelta >= 0.0
                                  ? PillChipType.green
                                  : PillChipType.red,
                            )
                          : null,
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
                      description: 'Total number of finished audits (last 30 days)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Overdue / Open APs',
                      '$overdueAPs / $openAPs',
                      description: 'Late action plans out of all active action plans',
                      isAlert: overdueAPs > 0,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BodApBucketDetailSheet(
                            bucketName: 'All',
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
                      'Active Stores',
                      '$activeStores',
                      description: 'Total stores with audit activity (last 30 days)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      context,
                      'Total Auditors',
                      '$totalAuditors',
                      description: 'Total unique auditors submitting audits',
                    ),
                  ),
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
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.wolf.withAlpha(160),
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
