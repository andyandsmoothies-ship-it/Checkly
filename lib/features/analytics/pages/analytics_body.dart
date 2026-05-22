import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';

import '../manager/analytics_data.dart';
import '../manager/analytics_manager.dart';
import '../widgets/trend_chart.dart';
import '../widgets/category_heatmap.dart';
import '../widgets/analytics_kpi_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/insights_radar_chart.dart';

/// Main scrollable content area of [AnalyticsPage].
///
/// Renders (in order):
/// - Offline warning banner (when [manager.isOffline])
/// - Filter chip bar [filterChips]
/// - Empty state OR KPI grid + trend + heatmap + insights + radar
class AnalyticsBody extends StatelessWidget {
  final AnalyticsManager manager;
  final int activeFilterCount;
  final Widget filterChips;

  const AnalyticsBody({
    super.key,
    required this.manager,
    required this.activeFilterCount,
    required this.filterChips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = manager.data;
    final totalAudits = data?.totalAudits ?? 0;

    return RefreshIndicator(
      onRefresh: manager.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Offline banner ──
          if (manager.isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Insights require an internet connection.',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Filter chip bar (injected by parent) ──
          filterChips,
          const SizedBox(height: 16),

          // ── Empty states ──
          if (totalAudits == 0 && activeFilterCount > 0)
            const ChecklyEmptyState(
              emoji: '🔍',
              title: "Let's widen the search!",
              subtitle:
                  'No audits match your current filters. Try clearing some filters to explore more data.',
            )
          else if (totalAudits == 0)
            const ChecklyEmptyState(
              emoji: '📊',
              title: 'Your insights dashboard is waiting!',
              subtitle:
                  'Complete your very first audit to unlock beautiful analytics and performance trends.',
            )
          else ...[
            // ── KPI Grid ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AnalyticsKpiCard(
                  icon: Icons.assignment,
                  label: 'Total Audits',
                  value: '$totalAudits',
                  accentColor: theme.colorScheme.primary,
                  tooltip: 'Total non-rejected audits',
                  onTap: () => context.go('/activity'),
                ),
                AnalyticsKpiCard(
                  icon: Icons.speed,
                  label: 'Avg Audit Score',
                  value: (data?.avgScore ?? 0).toStringAsFixed(1),
                  accentColor: AppTheme.success,
                  tooltip: 'Mean score of all scored audits',
                  onTap: () => context.go('/activity?filter=submitted'),
                ),
                AnalyticsKpiCard(
                  icon: Icons.pending_actions,
                  label: 'Action Plans',
                  value: '${data?.openAPs ?? 0}',
                  accentColor: AppTheme.warning,
                  tooltip: 'Action plans awaiting resolution',
                  onTap: () => context.go('/plans?filter=open'),
                ),
                AnalyticsKpiCard(
                  icon: Icons.warning_amber,
                  label: 'Overdue',
                  value: '${data?.overdueAPs ?? 0}',
                  accentColor: theme.colorScheme.error,
                  tooltip: 'Action plans past their deadline',
                  onTap: () => context.go('/plans?sort=urgent'),
                ),
                AnalyticsKpiCard(
                  icon: Icons.check_circle,
                  label: 'Completion Rate',
                  value: '${(data?.completionRate ?? 0).toStringAsFixed(1)}%',
                  accentColor: AppTheme.info,
                  onTap: () => context.go('/activity?filter=submitted'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const SectionHeader('6-MONTH TREND'),
            TrendChart(
              data: data?.trend ?? [],
              onMonthTap: (month) => context.go('/activity?month=$month'),
            ),

            const SizedBox(height: 24),

            const SectionHeader('CATEGORY PERFORMANCE'),
            CategoryHeatmap(categories: data?.categoryScores ?? []),

            // ── Insights section (online + non-empty only) ──
            if (!manager.isOffline && (data?.insights.isNotEmpty ?? false)) ...[
              const SizedBox(height: 24),
              const SectionHeader('INSIGHTS'),
              if (data!.insightsStale) const AnalyticsStaleBanner(),
              ...data.insights.map((i) => InsightCard(insight: i)),
            ],

            // ── Performance Radar section ──
            if (!manager.isOffline && data?.radarData != null) ...[
              const SizedBox(height: 24),
              const SectionHeader('PERFORMANCE RADAR'),
              InsightsRadarChart(radarData: data!.radarData),
            ],
          ],
        ],
      ),
    );
  }
}

/// Yellow banner shown above insight cards when the area benchmark snapshot
/// is older than 2 hours ([AnalyticsData.insightsStale] == true from API).
class AnalyticsStaleBanner extends StatelessWidget {
  const AnalyticsStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('insights_stale_banner'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppTheme.warningText, size: 16),
          const SizedBox(width: 6),
          Text(
            '⚠ Insights last updated over 2 hours ago',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warningText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
