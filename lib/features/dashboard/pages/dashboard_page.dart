import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/database/database_service.dart';
import '../manager/dashboard_manager.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../widgets/tactical_history_drawer.dart';

final _di = GetIt.instance;

/// Dashboard page — "Mission Control" matching PWA spec.
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
    _manager.loadStats();
  }

  Future<void> _openCategoryDrawer(String categoryType) async {
    final db = _di<DatabaseService>().db;

    // Find template IDs matching this category type
    final templates = await db.select(db.cachedTemplates).get();
    final catTemplateIds = templates
        .where((t) => t.type == categoryType)
        .map((t) => t.id)
        .toSet();

    // Query last 10 submissions for those templates
    final allSubs = await db.select(db.cachedSubmissions).get();
    final filtered =
        allSubs.where((s) => catTemplateIds.contains(s.templateId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final auditMaps = filtered
        .take(10)
        .map(
          (s) => <String, dynamic>{
            'id': s.id,
            'storeName': s.storeName ?? 'Unknown Store',
            'totalScore': s.totalScore,
            'status': s.status,
            'createdAt': s.createdAt.toIso8601String(),
          },
        )
        .toList();

    if (mounted) {
      TacticalHistoryDrawer.show(
        context,
        categoryName: categoryType,
        audits: auditMaps,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Control'),
        actions: const [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/templates'),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = _manager.stats;

          return RefreshIndicator(
            onRefresh: _manager.loadStats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Hero Card ──
                _HeroCard(
                  completed: stats.monthlyCompleted,
                  total: stats.monthlyTotal,
                ),
                const SizedBox(height: 20),

                // ── Quick Stats Row ──
                Row(
                  children: [
                    Expanded(
                      child: _QuickStat(
                        icon: Icons.pending_actions,
                        label: 'Action Plans',
                        value: '${stats.pendingActionPlanCount}',
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStat(
                        icon: Icons.warning_amber,
                        label: 'Overdue',
                        value: '${stats.overdueActionPlanCount}',
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStat(
                        icon: Icons.notifications_active,
                        label: 'Unread',
                        value: '${stats.unreadNotificationCount}',
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Per-Template Sections ──
                ...stats.templateCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => _openCategoryDrawer(cat.type),
                      child: _TemplateCategorySection(category: cat),
                    ),
                  ),
                ),

                // If no categories, show overall stats
                if (stats.templateCategories.isEmpty) ...[
                  _StatCard(
                    icon: Icons.assignment_turned_in,
                    label: 'Total Audits',
                    value: '${stats.recentAuditCount}',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.score,
                    label: 'Average Score',
                    value: '${stats.averageScore}%',
                    color: AppTheme.success,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Card (Monthly Progress Gauge) ──

class _HeroCard extends StatelessWidget {
  final int completed;
  final int total;

  const _HeroCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MONTHLY PLAN PROGRESS',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Circular gauge
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _GaugePainter(progress: progress),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountBadge(label: 'COMPLETED', value: '$completed'),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _CountBadge(label: 'TOTAL', value: '$total'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final String value;
  const _CountBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Quick Stat ──

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Template Category Section ──

class _TemplateCategorySection extends StatelessWidget {
  final TemplateCategoryStats category;

  const _TemplateCategorySection({required this.category});

  Color _categoryColor() => switch (category.type.toLowerCase()) {
    'quality_control' || 'quality control' => Colors.blue,
    'training' || 'training assessment' => Colors.green,
    'operations' => Colors.orange,
    'safety' => Colors.red,
    _ => Colors.teal,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.type.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              'VIEW ALL >',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Two stat cards side-by-side
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'ACTIVITY',
                value: '${category.pendingCount}',
                subtitle: 'pending',
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                label: 'WEAK STORES',
                value: '${category.weakStoreCount}',
                subtitle: 'score < 80%',
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fallback Stat Card ──

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
