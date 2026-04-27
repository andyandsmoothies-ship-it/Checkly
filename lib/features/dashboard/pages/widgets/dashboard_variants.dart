import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../../_shared/widgets/compact_status_panel.dart';
import '../../manager/dashboard_manager.dart';
import 'hero_card.dart';
import 'submission_feed_section.dart';

// ────────────────────────────────────────────────────────────────
// Loading Placeholder
// ────────────────────────────────────────────────────────────────

/// Shown while the manager is computing role-scoped stats.
class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Preparing your Command Center…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Auditor Variant
// ────────────────────────────────────────────────────────────────

/// Command Center for Auditors — focuses on drafts and personal APs.
class AuditorDashboardVariant extends StatelessWidget {
  final AuditorDashboardState state;
  final Future<void> Function()? onRefresh;
  const AuditorDashboardVariant({
    super.key,
    required this.state,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgFormatted = state.myAvgScore.truncateToDouble() == state.myAvgScore
        ? state.myAvgScore.toStringAsFixed(0)
        : state.myAvgScore.toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        children: [
          const SizedBox(height: 24),

          // ── Hero: Resume Draft ──
          if (state.draftCount > 0)
            HeroCard(
              icon: Icons.edit_outlined,
              title:
                  '${state.draftCount} Draft${state.draftCount > 1 ? 's' : ''} in Progress',
              subtitle: 'Tap to resume your latest audit',
              color: theme.colorScheme.primaryContainer,
              onTap: () => context.go('/activity?filter=draft'),
            ),

          if (state.draftCount > 0) const SizedBox(height: 16),

          // ── Compact Status Panel: Vitals ──
          CompactStatusPanel(
            metrics: [
              StatRowData(
                icon: Icons.pending_actions,
                label: 'Assigned Action Plans',
                value: '${state.openActionPlans}',
                iconColor: AppTheme.warning,
                onTap: () => context.go('/plans?filter=open'),
              ),
              StatRowData(
                icon: Icons.speed,
                label: 'My Avg Audit Score',
                value: avgFormatted,
                iconColor: AppTheme.success,
                onTap: () => context.push('/analytics'),
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
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Manager Variant (Store Manager & Area Manager)
// ────────────────────────────────────────────────────────────────

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

// ────────────────────────────────────────────────────────────────
// Admin Variant
// ────────────────────────────────────────────────────────────────

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

// ────────────────────────────────────────────────────────────────
// Shared sub-components
// ────────────────────────────────────────────────────────────────

/// Compact deadline warning banner.
@visibleForTesting
class DeadlineBanner extends StatelessWidget {
  final DateTime deadline;
  const DeadlineBanner({required this.deadline, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppTheme.warning),
          const SizedBox(width: 8),
          Text(
            'Next Action Plan Deadline: ${timeAgo(deadline)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
