import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';
import '../manager/bod_analytics_manager.dart';
import 'bod_mom_delta_chip.dart';
import 'bod_ap_bucket_detail_sheet.dart';
import 'bod_kpi_card.dart';

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
    final geofenceBypassCount = chainKpis['geofenceBypassCount'] ?? 0;
    final double? rawAvgTtrDays = chainKpis['avgTtrDays']?.toDouble();

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildRow1(context, theme, avgScore, completionRate, completionRateDelta),
              const SizedBox(height: 12),
              _buildRow2(context, rawAvgTtrDays, overdueAPs, openAPs),
              const SizedBox(height: 12),
              _buildRow3(totalAudits, activeStores),
              const SizedBox(height: 12),
              _buildRow4(totalAuditors, geofenceBypassCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildRow1(
    BuildContext context,
    ThemeData theme,
    double avgScore,
    double completionRate,
    double completionRateDelta,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BodKpiCard(
            label: 'Average Score',
            value: '${avgScore.toStringAsFixed(1)}%',
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
          child: BodKpiCard(
            label: 'Completion Rate',
            value: '${completionRate.toStringAsFixed(1)}%',
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
    );
  }

  Widget _buildRow2(
    BuildContext context,
    double? rawAvgTtrDays,
    int overdueAPs,
    int openAPs,
  ) {
    final String avgTtrDisplay = rawAvgTtrDays == null || rawAvgTtrDays <= 0.0
        ? 'N/A'
        : '${rawAvgTtrDays.toStringAsFixed(1)} days';

    final PillChip? avgTtrPill = rawAvgTtrDays == null || rawAvgTtrDays <= 0.0
        ? null
        : (rawAvgTtrDays <= 7.0
            ? const PillChip(label: 'Fast', type: PillChipType.green)
            : (rawAvgTtrDays <= 14.0
                ? const PillChip(label: 'On Pace', type: PillChipType.yellow)
                : const PillChip(label: 'Slow', type: PillChipType.red)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BodKpiCard(
            label: 'Avg TTR Days',
            value: avgTtrDisplay,
            description: 'Average days to resolve an action plan',
            rightIndicator: avgTtrPill,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BodKpiCard(
            label: 'Overdue / Open APs',
            value: '$overdueAPs / $openAPs',
            description: 'Late action plans out of all active action plans',
            isAlert: overdueAPs > 0,
            onTap: () => _showApBottomSheet(context),
          ),
        ),
      ],
    );
  }

  void _showApBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BodApBucketDetailSheet(
        bucket: BodAgingBucket.all,
        manager: manager,
      ),
    );
  }

  Widget _buildRow3(int totalAudits, int activeStores) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BodKpiCard(
            label: 'Total Audits',
            value: '$totalAudits',
            description: 'Total number of finished audits (last 30 days)',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BodKpiCard(
            label: 'Active Stores',
            value: '$activeStores',
            description: 'Total stores with audit activity (last 30 days)',
          ),
        ),
      ],
    );
  }

  Widget _buildRow4(int totalAuditors, int geofenceBypassCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BodKpiCard(
            label: 'Total Auditors',
            value: '$totalAuditors',
            description: 'Total unique auditors submitting audits',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BodKpiCard(
            label: 'Geofence Bypasses',
            value: '$geofenceBypassCount',
            description: 'Total audits completed outside geofence',
            isAlert: geofenceBypassCount > 0,
          ),
        ),
      ],
    );
  }

}
