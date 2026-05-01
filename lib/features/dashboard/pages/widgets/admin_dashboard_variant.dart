import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/compact_status_panel.dart';
import '../../manager/dashboard_manager.dart';
import 'submission_feed_section.dart';

/// Command Center for Admins — global platform view.
class AdminDashboardVariant extends StatelessWidget {
  final AdminDashboardState state;
  final Future<void> Function()? onRefresh;
  const AdminDashboardVariant({super.key, required this.state, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgFormatted =
        state.globalAvgScore.truncateToDouble() == state.globalAvgScore
        ? state.globalAvgScore.toStringAsFixed(0)
        : state.globalAvgScore.toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        children: [
          const SizedBox(height: 24),

          // ── Dashboard Title ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mission Control',
                style: AppFonts.serifStyle(
                  fontSize:
                      Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PLATFORM OVERVIEW',
                style: AppFonts.displayStyle(
                  fontSize:
                      Theme.of(context).textTheme.labelSmall?.fontSize ?? 11,
                  fontWeight: FontWeight.w500,
                  // WCAG fix: raised from 0.5 → 0.65
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Compact Status Panel: 4 KPIs ──
          CompactStatusPanel(
            metrics: [
              StatRowData(
                icon: Icons.pending_actions,
                label: 'Action Plans',
                value: '${state.openActionPlans}',
                iconColor: AppTheme.warning,
                onTap: () => context.go('/plans?filter=open'),
              ),
              StatRowData(
                icon: Icons.assignment,
                label: 'Total Audits',
                value: '${state.totalAudits}',
                iconColor: theme.colorScheme.primary,
                onTap: () => context.go('/activity'),
              ),
              StatRowData(
                icon: Icons.warning_amber,
                label: 'Overdue',
                value: '${state.overdueActionPlans}',
                iconColor: AppColors.destructive,
                onTap: () => context.go('/plans?sort=urgent'),
              ),
              StatRowData(
                icon: Icons.speed,
                label: 'Global Avg Audit Score',
                value: avgFormatted,
                iconColor: AppTheme.success,
                onTap: () => context.push('/analytics'),
              ),
              StatRowData(
                icon: Icons.campaign_outlined,
                label: 'Active Programs',
                value: 'View',
                iconColor: theme.colorScheme.tertiary,
                onTap: () => context.push('/programs'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          SubmissionFeedSection(
            submissions: state.recentSubmissions,
            context: context,
            theme: theme,
          ),
        ],
      ),
    );
  }
}
