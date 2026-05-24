import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/bod_analytics_manager.dart';
import '../widgets/bod_kpi_grid.dart';
import '../widgets/bod_score_trend.dart';
import '../widgets/bod_store_leaderboard.dart';
import '../widgets/bod_category_weakness.dart';
import '../widgets/bod_ap_aging_funnel.dart';
import '../widgets/bod_auditor_scatter.dart';

/// Boardroom (BOD) Executive Analytics Dashboard.
///
/// Capability gate: users without [AppCapabilities.analyticsBod]
/// are redirected to `/home` by the router.
///
/// Handles 4 distinct states:
/// - Loading: [CircularProgressIndicator] with a message
/// - Offline: [ChecklyEmptyState] with try again action
/// - Empty: [ChecklyEmptyState] with recompute action
/// - Success: Displays 6 premium StrokeCard panels in responsive layout
class BodAnalyticsPage extends StatefulWidget {
  const BodAnalyticsPage({super.key});

  @override
  State<BodAnalyticsPage> createState() => _BodAnalyticsPageState();
}

class _BodAnalyticsPageState extends State<BodAnalyticsPage> {
  late final BodAnalyticsManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = GetIt.I<BodAnalyticsManager>();
    _manager.loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boardroom Analytics'),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              final report = _manager.report;
              final isRefreshAllowed = report?.allowedActions.contains('refresh') ?? false;
              if (isRefreshAllowed && !_manager.isLoading) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _manager.refreshReport,
                  tooltip: 'Refresh Dashboard',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.macaw),
                  const SizedBox(height: 16),
                  Text(
                    'Fetching executive boardroom dashboard...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.wolf,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_manager.isOffline) {
            return Center(
              child: ChecklyEmptyState(
                icon: Icons.wifi_off_outlined,
                title: 'Connection Required',
                subtitle: 'BOD Analytics requires an active internet connection to download pre-computed dashboards.',
                actionButton: OutlinedButton(
                  onPressed: _manager.refreshReport,
                  child: const Text('Try Again'),
                ),
              ),
            );
          }

          if (_manager.isEmpty) {
            return Center(
              child: ChecklyEmptyState(
                icon: Icons.analytics_outlined,
                title: 'Boardroom Dashboard Empty',
                subtitle: 'No pre-computed report is available yet. Recomputation can be triggered manually.',
                actionButton: FilledButton(
                  onPressed: _manager.refreshReport,
                  child: const Text('Trigger Recomputation'),
                ),
              ),
            );
          }

          final report = _manager.report;
          if (report == null) {
            return Center(
              child: ChecklyEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'System Error',
                subtitle: 'An unexpected system error occurred while retrieving boardroom dashboard.',
                actionButton: FilledButton(
                  onPressed: _manager.loadReport,
                  child: const Text('Retry'),
                ),
              ),
            );
          }

          // Parse and format computedAt date in local system timezone
          String localDateStr = '';
          try {
            if (report.computedAt.isNotEmpty) {
              final parsed = DateTime.parse(report.computedAt).toLocal();
              localDateStr = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
            }
          } catch (_) {
            localDateStr = report.computedAt;
          }

          final double screenWidth = MediaQuery.of(context).size.width;
          final bool isWide = screenWidth > 720;

          final card1 = BodKpiGrid(chainKpis: report.chainKpis);
          final card2 = BodScoreTrend(trend: report.trend);
          final card3 = BodStoreLeaderboard(
            topStores: report.topStores,
            bottomStores: report.bottomStores,
          );
          final card4 = BodCategoryWeakness(categoryBreakdown: report.categoryBreakdown);
          final card5 = BodApAgingFunnel(apAging: report.apAging);
          final card6 = BodAuditorScatter(auditorProductivity: report.auditorProductivity);

          return RefreshIndicator(
            onRefresh: _manager.refreshReport,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          const Icon(Icons.warning_amber_rounded, color: AppColors.fox, size: 24),
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
        },
      ),
    );
  }
}
