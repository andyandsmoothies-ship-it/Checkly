import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/area_bod_manager.dart';
import '../widgets/area_bod_dashboard_body.dart';
import '../widgets/area_bod_region_filter_sheet.dart';

/// Area Boardroom (BOD) Analytics Dashboard.
///
/// Capability gate: users without [AppCapabilities.analyticsArea]
/// are redirected to `/home` by the router.
///
/// Handles 4 distinct states:
/// - Loading: [CircularProgressIndicator] with a message
/// - Offline: [ChecklyEmptyState] with try again action
/// - Empty: [ChecklyEmptyState] with recompute action
/// - Success: Displays AreaBodDashboardBody containing premium panels
class AreaBodAnalyticsPage extends StatefulWidget {
  const AreaBodAnalyticsPage({super.key});

  @override
  State<AreaBodAnalyticsPage> createState() => _AreaBodAnalyticsPageState();
}

class _AreaBodAnalyticsPageState extends State<AreaBodAnalyticsPage> {
  late final AreaBodManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = GetIt.I<AreaBodManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Analytics'),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              if (_manager.report == null || _manager.isLoading) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: theme.colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) =>
                        AreaBodRegionFilterSheet(manager: _manager),
                  );
                },
                tooltip: 'Filter Region',
              );
            },
          ),
          ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              final report = _manager.report;
              final isRefreshAllowed =
                  report?.allowedActions.contains('refresh') ?? false;
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
                    'Fetching area boardroom dashboard...',
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
                subtitle:
                    'Area BOD Analytics requires an active internet connection to download pre-computed dashboards.',
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
                title: 'Area Dashboard Empty',
                subtitle:
                    'No pre-computed report is available yet. Recomputation can be triggered manually.',
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
                subtitle:
                    'An unexpected system error occurred while retrieving area dashboard.',
                actionButton: FilledButton(
                  onPressed: _manager.loadReport,
                  child: const Text('Retry'),
                ),
              ),
            );
          }

          return AreaBodDashboardBody(manager: _manager, report: report);
        },
      ),
    );
  }
}
