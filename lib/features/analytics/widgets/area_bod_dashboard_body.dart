import 'package:flutter/material.dart';
import '../manager/area_bod_data.dart';
import '../manager/area_bod_manager.dart';
import 'area_bod_kpi_grid.dart';
import 'area_bod_score_trend.dart';
import 'area_bod_store_leaderboard.dart';
import 'area_bod_category_weakness.dart';
import 'area_bod_ap_aging_funnel.dart';
import 'area_bod_auditor_scatter.dart';

/// Boardroom Dashboard Body containing the 6 primary interactive analytics panels.
class AreaBodDashboardBody extends StatelessWidget {
  final AreaBodManager manager;
  final AreaBodResponse report;

  const AreaBodDashboardBody({
    super.key,
    required this.manager,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: manager.refreshReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel 1: KPI Grid
            AreaBodKpiGrid(
              kpis: report.kpis,
              trend: report.trend,
              goldenStore: report.goldenStore,
              manager: manager,
            ),
            const SizedBox(height: 16),

            // Panel 2: Historical Score Trend
            AreaBodScoreTrend(
              trend: report.trend,
              goldenStore: report.goldenStore,
            ),
            const SizedBox(height: 16),

            // Panel 3: Store Leaderboard
            AreaBodStoreLeaderboard(
              topStores: report.topStores,
              bottomStores: report.bottomStores,
              goldenStore: report.goldenStore,
            ),
            const SizedBox(height: 16),

            // Panel 4: Category Weakness Analysis
            AreaBodCategoryWeakness(weaknesses: report.weaknesses),
            const SizedBox(height: 16),

            // Panel 5: AP Aging Funnel
            AreaBodApAgingFunnel(
              apAging: report.actionPlanAging,
              avgTtrDays: report.kpis.avgTtrDays,
              manager: manager,
            ),
            const SizedBox(height: 16),

            // Panel 6: Auditor Scatter Chart & Productivity List
            AreaBodAuditorScatter(auditors: report.auditorProductivity),
          ],
        ),
      ),
    );
  }
}
