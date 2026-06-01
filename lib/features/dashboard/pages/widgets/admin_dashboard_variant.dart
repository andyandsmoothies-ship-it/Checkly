import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/widgets/primitives/stroke_card.dart';
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
        children: [
          const SizedBox(height: 12),

          // Premium 2x2 Grid of KPIs
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _AdminKpiCard(
                icon: Icons.assignment,
                label: 'TOTAL AUDITS',
                value: '${state.totalAudits}',
                iconColor: AppColors.humpback,
                backgroundColor: const Color(0xFFDDF4FF),
                borderColor: AppColors.blueJay,
                onTap: () => context.go('/activity'),
              ),
              _AdminKpiCard(
                icon: Icons.speed,
                label: 'AVG SCORE',
                value: avgFormatted,
                iconColor: const Color(0xFF388E3C),
                backgroundColor: AppColors.seaSponge,
                borderColor: AppColors.turtle,
                onTap: () => context.push('/analytics'),
              ),
              _AdminKpiCard(
                icon: Icons.hourglass_empty,
                label: 'OPEN PLANS',
                value: '${state.openActionPlans}',
                iconColor: AppColors.fox,
                backgroundColor: AppColors.canary,
                borderColor: AppColors.duck,
                onTap: () => context.go('/plans?filter=open'),
              ),
              _AdminKpiCard(
                icon: Icons.warning_amber,
                label: 'OVERDUE PLANS',
                value: '${state.overdueActionPlans}',
                iconColor: AppColors.destructive,
                backgroundColor: const Color(0xFFFFEBEB),
                borderColor: AppColors.destructive,
                onTap: () => context.go('/plans?sort=urgent'),
              ),
            ],
          ),

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

/// A premium, distinct card representing a single boardroom KPI metric, with tap support.
class _AdminKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _AdminKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: StrokeCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.eel,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
