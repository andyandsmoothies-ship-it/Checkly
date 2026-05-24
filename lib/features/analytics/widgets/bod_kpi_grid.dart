import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodKpiGrid extends StatelessWidget {
  final Map<String, dynamic> chainKpis;

  const BodKpiGrid({super.key, required this.chainKpis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalAudits = chainKpis['totalAudits'] ?? 0;
    final avgScore = chainKpis['avgScore']?.toDouble() ?? 0.0;
    final avgScoreDelta = chainKpis['avgScoreDelta']?.toDouble() ?? 0.0;
    final completionRate = chainKpis['completionRate']?.toDouble() ?? 0.0;
    final completionRateDelta = chainKpis['completionRateDelta']?.toDouble() ?? 0.0;
    final openAPs = chainKpis['openAPs'] ?? 0;
    final overdueAPs = chainKpis['overdueAPs'] ?? 0;

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.featherGreen, size: 24),
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
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKpiCard(
                context,
                'Average Score',
                '${avgScore.toStringAsFixed(1)}%',
                delta: avgScoreDelta,
              ),
              _buildKpiCard(
                context,
                'Completion Rate',
                '${completionRate.toStringAsFixed(1)}%',
                delta: completionRateDelta,
              ),
              _buildKpiCard(
                context,
                'Total Audits',
                '$totalAudits',
              ),
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
    double? delta,
    bool isAlert = false,
  }) {
    final theme = Theme.of(context);
    final bool hasDelta = delta != null && delta != 0.0;
    final bool isPositive = delta != null && delta >= 0.0;

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isAlert ? AppColors.cardinal : AppColors.eel,
              ),
            ),
          ),
          if (hasDelta) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: isPositive ? AppColors.featherGreen : AppColors.cardinal,
                ),
                const SizedBox(width: 2),
                Text(
                  '${delta.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isPositive ? AppColors.featherGreen : AppColors.cardinal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
