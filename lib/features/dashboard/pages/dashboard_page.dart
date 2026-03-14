import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/checkly_fab.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/database/database_service.dart';
import '../../auth/manager/auth_manager.dart';
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
      floatingActionButton: ChecklyFab(
        label: 'AUDIT',
        onPressed: () => context.push('/templates'),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                // ── Apothecary Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: AppFonts.serifStyle(
                              fontSize: 30,
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
                    const NotificationBell(),
                  ],
                ),

                // ── Circular Progress Ring ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: 192,
                      height: 192,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: progress,
                          trackColor: AppTheme.sageGray.withValues(alpha: 0.3),
                          progressColor: theme.colorScheme.primary,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$percentage%',
                                style: AppFonts.serifStyle(
                                  fontSize: 48,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              Text(
                                'SCORE',
                                style: AppFonts.displayStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.charcoal.withValues(
                                    alpha: 0.5,
                                  ),
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Asymmetric Stats ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Large softPeach block (h-40)
                    Expanded(
                      child: Container(
                        height: 160,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.softPeach,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${stats.pendingActionPlanCount}',
                              style: AppFonts.serifStyle(
                                fontSize: 36,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Open Action Plans',
                              style: AppFonts.displayStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.charcoal.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Narrow white block with sage border (h-32)
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.sageGray.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${stats.recentAuditCount}',
                              style: AppFonts.serifStyle(
                                fontSize: 24,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AUDITS',
                              style: AppFonts.displayStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.charcoal.withValues(alpha: 0.6),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Recent Scans Section Header ──
                Text(
                  'RECENT SCANS',
                  style: AppFonts.displayStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal.withValues(alpha: 0.4),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),

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

// ── Progress Ring Painter (Apothecary) ──

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
