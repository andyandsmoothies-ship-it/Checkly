import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/widgets/compact_status_panel.dart';
import '../../manager/dashboard_manager.dart';
import 'hero_card.dart';
import 'submission_feed_section.dart';
import 'deadline_banner.dart';
import 'action_required_widget.dart';

/// Command Center for Store Managers and Area Managers.
/// Both use [ManagerDashboardState]; role string controls the title.
class ManagerDashboardVariant extends StatelessWidget {
  final ManagerDashboardState state;
  final String role;
  final Future<void> Function()? onRefresh;
  const ManagerDashboardVariant({
    super.key,
    required this.state,
    required this.role,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArea = role == 'area_manager';
    final contextLabel = isArea ? 'Your Area Fleet' : 'Your Store';
    final avgFormatted =
        state.storeAvgScore.truncateToDouble() == state.storeAvgScore
        ? state.storeAvgScore.toStringAsFixed(0)
        : state.storeAvgScore.toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        children: [
          const SizedBox(height: 24),

          // ── Programs: Action Required Banner ──
          const ActionRequiredWidget(),

          // ── Hero: Action Required Banner ──
          if (state.overdueActionPlans > 0)
            HeroCard(
              icon: Icons.warning_amber_rounded,
              title:
                  '${state.overdueActionPlans} Overdue Action Plan${state.overdueActionPlans > 1 ? 's' : ''}',
              subtitle: '$contextLabel · Immediate attention needed',
              color: AppColors.destructive.withValues(alpha: 0.10),
              iconColor: AppColors.destructive,
              onTap: () => context.go('/plans?sort=urgent'),
            )
          else
            HeroCard(
              icon: Icons.check_circle_outline,
              title: 'All Clear — No Overdue Plans',
              subtitle: '$contextLabel · ${state.storeName ?? ''}',
              color: AppTheme.success.withValues(alpha: 0.10),
              iconColor: AppTheme.success,
              onTap: () => context.go('/plans'),
            ),

          const SizedBox(height: 16),

          // ── Compact Status Panel ──
          CompactStatusPanel(
            metrics: [
              StatRowData(
                icon: Icons.pending_actions,
                label: isArea ? 'Area Action Plans' : 'Store Action Plans',
                value: '${state.openActionPlans}',
                iconColor: AppTheme.warning,
                onTap: () => context.go('/plans?filter=open'),
              ),
              StatRowData(
                icon: Icons.speed,
                label: isArea ? 'Area Avg Score' : 'Store Avg Score',
                value: avgFormatted,
                iconColor: AppTheme.success,
                onTap: () => context.push('/analytics'),
              ),
              // Approvals quick-link: visible only if user holds submissions:review.
              // Area Managers with this capability can reach /admin/approvals
              // (router whitelist applied in app_router.dart).
              if (GetIt.instance<PolicyManager>().can(
                AppCapabilities.submissionsReview,
              ))
                StatRowData(
                  icon: Icons.fact_check_outlined,
                  label: 'Pending Approvals',
                  value: 'View →',
                  iconColor: theme.colorScheme.primary,
                  onTap: () => context.push('/admin/approvals'),
                ),
            ],
          ),

          if (state.nearestDeadline != null) ...[
            const SizedBox(height: 12),
            DeadlineBanner(deadline: state.nearestDeadline!),
          ],

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
