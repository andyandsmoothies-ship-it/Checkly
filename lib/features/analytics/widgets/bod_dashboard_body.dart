import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/bod_analytics_data.dart';
import '../manager/bod_analytics_manager.dart';
import 'bod_kpi_grid.dart';
import 'bod_score_trend.dart';
import 'bod_store_leaderboard.dart';
import 'bod_category_weakness.dart';
import 'bod_ap_aging_funnel.dart';
import 'bod_auditor_scatter.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';

/// The success state dashboard body.
///
/// Contains the regional filter bar and responsive layout displaying 6 cards.
class BodDashboardBody extends StatelessWidget {
  final BodAnalyticsManager manager;
  final BodReportResponse report;

  const BodDashboardBody({
    super.key,
    required this.manager,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse and format computedAt date in local system timezone
    String localDateStr = '';
    try {
      if (report.computedAt.isNotEmpty) {
        final parsed = DateTime.parse(report.computedAt).toLocal();
        localDateStr =
            '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      localDateStr = report.computedAt;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 720;

    // ── DIAGNOSTIC: try-catch each card so Debug Console reports which card crashes ──
    Widget card1;
    try {
      card1 = BodKpiGrid(
        chainKpis: report.chainKpis.toJson(),
        trend: report.trend,
        goldenStore: report.goldenStore,
        manager: manager,
      );
    } catch (e, s) {
      debugPrint('🔴 BOD card1 (BodKpiGrid) CRASH: $e\n$s');
      rethrow;
    }

    Widget card2;
    try {
      card2 = BodScoreTrend(trend: report.trend);
    } catch (e, s) {
      debugPrint('🔴 BOD card2 (BodScoreTrend) CRASH: $e\n$s');
      rethrow;
    }

    Widget card3;
    try {
      card3 = BodStoreLeaderboard(
        topStores: report.topStores,
        bottomStores: report.bottomStores,
        manager: manager,
      );
    } catch (e, s) {
      debugPrint('🔴 BOD card3 (BodStoreLeaderboard) CRASH: $e\n$s');
      rethrow;
    }

    Widget card4;
    try {
      card4 = BodCategoryWeakness(
        categoryBreakdown: report.categoryBreakdown,
        manager: manager,
      );
    } catch (e, s) {
      debugPrint('🔴 BOD card4 (BodCategoryWeakness) CRASH: $e\n$s');
      rethrow;
    }

    Widget card5;
    try {
      card5 = BodApAgingFunnel(
        apAging: report.apAging.toJson(),
        avgTtrDays: report.chainKpis.avgTtrDays,
        manager: manager,
      );
    } catch (e, s) {
      debugPrint('🔴 BOD card5 (BodApAgingFunnel) CRASH: $e\n$s');
      rethrow;
    }

    Widget card6;
    try {
      card6 = BodAuditorScatter(
        auditorProductivity: report.auditorProductivity,
        manager: manager,
        nationalAvg: report.chainKpis.avgScore,
      );
    } catch (e, s) {
      debugPrint('🔴 BOD card6 (BodAuditorScatter) CRASH: $e\n$s');
      rethrow;
    }

    return RefreshIndicator(
      onRefresh: manager.refreshReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: manager,
              builder: (context, _) {
                final province = manager.activeProvince;
                final district = manager.activeDistrict;
                if (province == null || district == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? AppColors.swan
                          : AppColors.swan.withValues(alpha: 0.2),
                      width: 2.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        color: theme.brightness == Brightness.light
                            ? AppColors.eel
                            : AppColors.snow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PillChip(
                              label: province,
                              type: PillChipType.blue,
                              icon: const Icon(
                                Icons.location_city_rounded,
                                size: 14,
                                color: AppColors.humpback,
                              ),
                              onTap: manager.clearFilter,
                            ),
                            PillChip(
                              label: district,
                              type: PillChipType.purple,
                              icon: const Icon(
                                Icons.map_rounded,
                                size: 14,
                                color: AppColors.beetle,
                              ),
                              onTap: manager.clearFilter,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: manager.clearFilter,
                        icon: const Icon(Icons.cancel_rounded, color: AppColors.cardinal),
                        tooltip: 'Clear filters',
                      ),
                    ],
                  ),
                );
              },
            ),

            if (report.snapshotStatus == 'PartiallyFailed') ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.fox, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.fox,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Some board metrics could not be fully calculated due to temporary database timeouts. Leaderboard scores may be incomplete.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.eel,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Executive Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
                if (localDateStr.isNotEmpty)
                  Text(
                    'Data as of $localDateStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.wolf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        card1,
                        const SizedBox(height: 16),
                        card3,
                        const SizedBox(height: 16),
                        card5,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        card2,
                        const SizedBox(height: 16),
                        card4,
                        const SizedBox(height: 16),
                        card6,
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  card1,
                  const SizedBox(height: 16),
                  card2,
                  const SizedBox(height: 16),
                  card3,
                  const SizedBox(height: 16),
                  card4,
                  const SizedBox(height: 16),
                  card5,
                  const SizedBox(height: 16),
                  card6,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
