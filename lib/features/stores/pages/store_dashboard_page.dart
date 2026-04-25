import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/utils/date_format_utils.dart';
import '../../../_shared/utils/score_utils.dart';
import '../manager/store_dashboard_manager.dart';

final _di = GetIt.instance;

/// 6C: Store Dashboard — single-store detail with audit history and AP summary.
///
/// Apothecary design: flat sage-bordered cards, serif accent numbers,
/// Manrope labels, warm cream background.
class StoreDashboardPage extends StatefulWidget {
  final String storeId;
  const StoreDashboardPage({super.key, required this.storeId});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  late final StoreDashboardManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<StoreDashboardManager>();
    _manager.load(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final theme = Theme.of(context);
        final data = _manager.data;

        return Scaffold(
          appBar: AppBar(title: Text(data?.storeName ?? 'Store')),
          body: _manager.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Score overview card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.sageGray.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Trailing 6-Month Avg Audit Score',
                            style: AppFonts.displayStyle(
                              fontSize: theme.textTheme.labelSmall?.fontSize,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(data?.avgScore ?? 0).toStringAsFixed(1)}%',
                            style: AppFonts.serifStyle(
                              fontSize:
                                  theme.textTheme.displaySmall?.fontSize ?? 40,
                              fontWeight: FontWeight.w700,
                              color: scoreColor(
                                data?.avgScore ?? 0,
                                Theme.of(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MetricChip(
                                label: 'Activities',
                                value: '${data?.recentAudits.length ?? 0}',
                                icon: Icons.assignment_outlined,
                              ),
                              const SizedBox(width: 20),
                              _MetricChip(
                                label: 'Action Plans',
                                value: '${data?.openAPs ?? 0}',
                                icon: Icons.pending_actions_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Recent Audits header ──
                    Text(
                      'RECENT AUDITS',
                      style: AppFonts.displayStyle(
                        fontSize: theme.textTheme.labelSmall?.fontSize,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Audit list ──
                    if (data == null || data.recentAudits.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.sageGray.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'No audits found for this store.',
                            style: AppFonts.displayStyle(
                              fontSize: theme.textTheme.bodyMedium?.fontSize,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(data.recentAudits.length, (i) {
                        final s = data.recentAudits[i];
                        final score = s.totalScore ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.sageGray.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: scoreColor(
                                  score,
                                  Theme.of(context),
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${score.toStringAsFixed(0)}%',
                                style: AppFonts.serifStyle(
                                  fontSize:
                                      theme.textTheme.labelSmall?.fontSize ??
                                      13,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor(score, Theme.of(context)),
                                ),
                              ),
                            ),
                            title: Text(
                              s.templateTitle ?? 'Audit',
                              style: AppFonts.displayStyle(
                                fontSize: theme.textTheme.bodyMedium?.fontSize,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${s.auditorName ?? 'Unknown'} • ${formatDate(s.createdAt)}',
                              style: AppFonts.displayStyle(
                                fontSize: theme.textTheme.bodySmall?.fontSize,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        );
                      }),

                    // View All History button
                    if (data != null && data.recentAudits.isNotEmpty)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/activity'),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('View All History'),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Metric chip with icon + label — Apothecary style.
class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.sageGray),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: AppFonts.displayStyle(
            fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
