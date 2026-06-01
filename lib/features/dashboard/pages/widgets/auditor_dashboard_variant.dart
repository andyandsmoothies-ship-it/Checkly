import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/widgets/compact_status_panel.dart';
import '../../manager/dashboard_manager.dart';
import 'hero_card.dart';
import 'submission_feed_section.dart';
import 'deadline_banner.dart';

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

          // ── Hero: Resume Draft or Start Audit ──
          state.draftCount > 0
              ? HeroCard(
                  icon: Icons.edit_outlined,
                  title:
                      '${state.draftCount} Draft${state.draftCount > 1 ? 's' : ''} in Progress',
                  subtitle: 'Tap to resume your latest audit',
                  color: theme.colorScheme.primaryContainer,
                  onTap: () => context.go('/activity?filter=draft'),
                )
              : HeroCard(
                  icon: Icons.add_circle_outline,
                  title: 'Start New Audit',
                  subtitle: 'Select a template to begin',
                  color: theme.colorScheme.secondaryContainer,
                  onTap: () => context.push('/templates'),
                ),

          const SizedBox(height: 16),

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
