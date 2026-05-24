import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';
import 'bod_mom_delta_chip.dart';

/// KPI Grid component displaying executive boardroom chain performance insights.
///
/// Features a flagship benchmark comparison to the highest-performing global store
/// and Month-over-Month trend delta pill chips.
class BodKpiGrid extends StatelessWidget {
  final Map<String, dynamic> chainKpis;
  final List<dynamic> trend;
  final BodGoldenStore? goldenStore;

  const BodKpiGrid({
    super.key,
    required this.chainKpis,
    required this.trend,
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
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            childAspectRatio:
                1.35, // Adjusted to fit the flagship benchmark comparison nicely
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKpiCard(
                context,
                'Average Score',
                '${avgScore.toStringAsFixed(1)}%',
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
              _buildKpiCard(
                context,
                'Completion Rate',
                '${completionRate.toStringAsFixed(1)}%',
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
              _buildKpiCard(context, 'Total Audits', '$totalAudits'),
              _buildKpiCard(
                context,
                'Overdue / Open APs',
                '$overdueAPs / $openAPs',
                isAlert: overdueAPs > 0,
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
    Widget? rightIndicator,
    Widget? footer,
    bool isAlert = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 4),
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
  }
}
