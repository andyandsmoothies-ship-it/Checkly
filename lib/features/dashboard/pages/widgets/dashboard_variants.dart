import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../../_shared/widgets/section_header.dart';
import '../../../../_shared/database/app_database.dart';
import '../../manager/dashboard_manager.dart';

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
            _HeroCard(
              icon: Icons.edit_outlined,
              title:
                  '${state.draftCount} Draft${state.draftCount > 1 ? 's' : ''} in Progress',
              subtitle: 'Tap to resume your latest audit',
              color: theme.colorScheme.primaryContainer,
              onTap: () => context.go('/activity?filter=draft'),
            ),

          if (state.draftCount > 0) const SizedBox(height: 16),

          // ── Bento Box: Vitals ──
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.pending_actions,
                  label: 'Action Plans',
                  subtitle: 'ASSIGNED TO YOU',
                  value: '${state.openActionPlans}',
                  color: const Color(0xFFFEEAD1),
                  iconColor: AppTheme.warning,
                  onTap: () => context.go('/plans?filter=open'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.speed,
                  label: 'My Avg Audit Score',
                  subtitle: 'AUDITS I PERFORMED',
                  value: '$avgFormatted%',
                  color: AppTheme.success.withValues(alpha: 0.08),
                  iconColor: AppTheme.success,
                  onTap: () => context.push('/analytics'),
                ),
              ),
            ],
          ),

          if (state.nearestDeadline != null) ...[
            const SizedBox(height: 12),
            _DeadlineBanner(deadline: state.nearestDeadline!),
          ],

          const SizedBox(height: 32),
          _SubmissionFeedSection(
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
  const ManagerDashboardVariant({
    super.key,
    required this.state,
    required this.role,
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      children: [
        const SizedBox(height: 24),

        // ── Hero: Action Required Banner ──
        if (state.overdueActionPlans > 0)
          _HeroCard(
            icon: Icons.warning_amber_rounded,
            title:
                '${state.overdueActionPlans} Overdue Action Plan${state.overdueActionPlans > 1 ? 's' : ''}',
            subtitle: '$contextLabel · Immediate attention needed',
            color: Colors.red.withValues(alpha: 0.10),
            iconColor: Colors.red,
            onTap: () => context.go('/plans?sort=urgent'),
          )
        else
          _HeroCard(
            icon: Icons.check_circle_outline,
            title: 'All Clear — No Overdue Plans',
            subtitle: '$contextLabel · ${state.storeName ?? ''}',
            color: AppTheme.success.withValues(alpha: 0.10),
            iconColor: AppTheme.success,
            onTap: () => context.go('/plans'),
          ),

        const SizedBox(height: 16),

        // ── Bento Box ──
        Row(
          children: [
            Expanded(
              child: _DashboardStatCard(
                icon: Icons.pending_actions,
                label: 'Action Plans',
                subtitle: isArea ? 'IN YOUR AREA' : 'AT THIS STORE',
                value: '${state.openActionPlans}',
                color: const Color(0xFFFEEAD1),
                iconColor: AppTheme.warning,
                onTap: () => context.go('/plans?filter=open'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardStatCard(
                icon: Icons.speed,
                label: isArea
                    ? 'Area Avg Audit Score'
                    : 'Store Avg Audit Score',
                subtitle: isArea ? 'STORES IN REGION' : 'THIS LOCATION ONLY',
                value: '$avgFormatted%',
                color: AppTheme.success.withValues(alpha: 0.08),
                iconColor: AppTheme.success,
                onTap: () => context.push('/analytics'),
              ),
            ),
          ],
        ),

        if (state.nearestDeadline != null) ...[
          const SizedBox(height: 12),
          _DeadlineBanner(deadline: state.nearestDeadline!),
        ],

        const SizedBox(height: 32),
        _SubmissionFeedSection(
          submissions: state.recentSubmissions,
          context: context,
          theme: theme,
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Admin Variant
// ────────────────────────────────────────────────────────────────

/// Command Center for Admins — global platform view.
class AdminDashboardVariant extends StatelessWidget {
  final AdminDashboardState state;
  const AdminDashboardVariant({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.monthlyTotal > 0
        ? (state.monthlyCompleted / state.monthlyTotal).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);
    final avgFormatted =
        state.globalAvgScore.truncateToDouble() == state.globalAvgScore
        ? state.globalAvgScore.toStringAsFixed(0)
        : state.globalAvgScore.toStringAsFixed(1);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        children: [
          const SizedBox(height: 24),

          // ── Monthly Progress Ring ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Control',
                      style: AppFonts.serifStyle(
                        fontSize: 26,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PLATFORM OVERVIEW',
                      style: AppFonts.displayStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.charcoal.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (progress == 0.0)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.sageGray.withValues(alpha: 0.3),
                            width: 4,
                          ),
                        ),
                      )
                    else
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppTheme.sageGray.withValues(
                          alpha: 0.3,
                        ),
                        color: theme.colorScheme.primary,
                      ),
                    Text(
                      '$percentage%',
                      style: AppFonts.serifStyle(
                        fontSize: 16,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Bento Box: 4-cell grid ──
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.pending_actions,
                  label: 'Action Plans',
                  subtitle: 'ACROSS PLATFORM',
                  value: '${state.openActionPlans}',
                  color: const Color(0xFFFEEAD1),
                  iconColor: AppTheme.warning,
                  onTap: () => context.go('/plans?filter=open'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.assignment,
                  label: 'Total Audits',
                  subtitle: 'ALL-TIME COMPLETIONS',
                  value: '${state.totalAudits}',
                  color: theme.colorScheme.surface,
                  iconColor: theme.colorScheme.primary,
                  onTap: () => context.go('/activity'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.warning_amber,
                  label: 'Overdue',
                  subtitle: 'ACROSS PLATFORM',
                  value: '${state.overdueActionPlans}',
                  color: Colors.red.withValues(alpha: 0.08),
                  iconColor: Colors.red,
                  onTap: () => context.go('/plans?sort=urgent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardStatCard(
                  icon: Icons.speed,
                  label: 'Global Avg Audit Score',
                  subtitle: 'ALL STORES GLOBALLY',
                  value: '$avgFormatted%',
                  color: AppTheme.success.withValues(alpha: 0.08),
                  iconColor: AppTheme.success,
                  onTap: () => context.push('/analytics'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _SubmissionFeedSection(
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

/// Hero banner card — draws attention to a primary action.
class _HeroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _HeroCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ic = iconColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ic.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ic, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.serifStyle(
                        fontSize: 16,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.charcoal.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact deadline warning banner.
class _DeadlineBanner extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineBanner({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppTheme.warning),
          const SizedBox(width: 8),
          Text(
            'Nearest deadline: ${timeAgo(deadline)}',
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

/// Stat card — the Bento Box cell.
class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String value;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardStatCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 2),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.charcoal.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppFonts.serifStyle(
                  fontSize: 32,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: AppFonts.displayStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.charcoal.withValues(alpha: 0.35),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Recent submissions feed section — shared across all variants.
class _SubmissionFeedSection extends StatelessWidget {
  final List<CachedSubmission> submissions;
  final BuildContext context;
  final ThemeData? theme;

  const _SubmissionFeedSection({
    required this.submissions,
    required this.context,
    this.theme,
  });

  @override
  Widget build(BuildContext ctx) {
    final t = theme ?? Theme.of(ctx);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: t.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SectionHeader('LATEST SUBMISSIONS')),
            InkWell(
              onTap: () => context.go('/activity'),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW ALL',
                      style: t.textTheme.labelSmall?.copyWith(
                        color: t.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: t.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (submissions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No audits yet — start your first one!',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...submissions.map(
            (sub) => _SubmissionRow(submission: sub, context: context),
          ),
      ],
    );
  }
}

/// Single submission row in the feed.
class _SubmissionRow extends StatelessWidget {
  final CachedSubmission submission;
  final BuildContext context;

  const _SubmissionRow({required this.submission, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final score = submission.totalScore;
    final scoreColor = score != null
        ? (score >= 80 ? AppTheme.success : Colors.red)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/activity'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.templateTitle ?? 'Audit',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${submission.storeName ?? 'Unknown'} · ${timeAgo(submission.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (score != null)
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: AppFonts.serifStyle(fontSize: 22, color: scoreColor),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    submission.status.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
