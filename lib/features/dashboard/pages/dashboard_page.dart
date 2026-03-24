import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/checkly_fab.dart';
import '../../admin/pages/schedule_audit_page.dart';
import '../../auth/manager/auth_manager.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/utils/date_format_utils.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../../_shared/database/app_database.dart';
import '../manager/dashboard_manager.dart';
import '../../notifications/widgets/notification_bell.dart';

final _di = GetIt.instance;

/// Dashboard page — "The Checkly Stream" enterprise layout.
/// Compact header + Bento Box action cards + chronological submission feed.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<DashboardManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadStats();
    });
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Assign Task',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScheduleAuditForm(onSuccess: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: ChecklyFab(
        isAdmin: GetIt.instance<AuthManager>().currentUser?.role == 'admin',
        onNewAudit: () => context.push('/templates'),
        onAssignTask: () => _showScheduleSheet(context),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const _DashboardSkeleton();
          }

          final stats = _manager.stats;
          final progress = stats.monthlyTotal > 0
              ? (stats.monthlyCompleted / stats.monthlyTotal).clamp(0.0, 1.0)
              : 0.0;
          final percentage = (progress * 100).toStringAsFixed(0);

          return RefreshIndicator(
            onRefresh: _manager.loadStats,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              children: [
                // ── Compact Header: Greeting + Progress ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: AppFonts.serifStyle(
                              fontSize: 26,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MISSION CONTROL',
                            style: AppFonts.displayStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoal.withValues(alpha: 0.6),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Compact progress indicator
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
                                  color: AppTheme.sageGray.withValues(
                                    alpha: 0.3,
                                  ),
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
                    const SizedBox(width: 12),
                    const NotificationBell(),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Bento Box: Action Center ──
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        icon: Icons.pending_actions,
                        label: 'Open APs',
                        value: '${stats.pendingActionPlanCount}',
                        color: const Color(0xFFFEEAD1), // soft peach
                        iconColor: AppTheme.warning,
                        onTap: () => context.go('/plans?filter=open'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardCard(
                        icon: Icons.assignment,
                        label: 'Audits',
                        value: '${stats.recentAuditCount}',
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
                      child: _DashboardCard(
                        icon: Icons.warning_amber,
                        label: 'Overdue',
                        value: '${stats.overdueActionPlanCount}',
                        color: Colors.red.withValues(alpha: 0.08),
                        iconColor: Colors.red,
                        onTap: () => context.go('/plans?sort=urgent'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DashboardCard(
                        icon: Icons.speed,
                        label: 'Avg Score',
                        value:
                            '${stats.averageScore.truncateToDouble() == stats.averageScore ? stats.averageScore.toStringAsFixed(0) : stats.averageScore.toStringAsFixed(1)}%',
                        color: AppTheme.success.withValues(alpha: 0.08),
                        iconColor: AppTheme.success,
                        onTap: () => context.push('/analytics'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Latest Submissions Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VIEW ALL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Submission Feed ──
                if (stats.recentSubmissions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No audits yet — start your first one!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...stats.recentSubmissions.map(
                    (sub) => _SubmissionFeedRow(submission: sub),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final name = _di<AuthManager>().currentUser?.email.split('@').first ?? '';
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    return name.isNotEmpty ? '$timeGreeting, $name' : timeGreeting;
  }
}

// ── Bento Box Card ──

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Submission Feed Row ──

class _SubmissionFeedRow extends StatelessWidget {
  final CachedSubmission submission;

  const _SubmissionFeedRow({required this.submission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

// ── Dashboard Loading Skeleton ──

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      children: [
        // Header shimmer
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 200, height: 28),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 140, height: 14),
                ],
              ),
            ),
            _ShimmerBox(width: 64, height: 64),
          ],
        ),
        const SizedBox(height: 24),

        // Bento box shimmer
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 110)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 110)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 110)),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 110)),
          ],
        ),
        const SizedBox(height: 32),

        // Feed shimmer
        const _ShimmerBox(width: 160, height: 14),
        const SizedBox(height: 12),
        _ShimmerBox(height: 72),
        const SizedBox(height: 8),
        _ShimmerBox(height: 72),
        const SizedBox(height: 8),
        _ShimmerBox(height: 72),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;

  const _ShimmerBox({this.width, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
