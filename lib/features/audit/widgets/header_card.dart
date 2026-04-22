import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/submission_dto.dart';
import '../utils/score_formatter.dart';
import '../../../_shared/theme/app_theme.dart';

class HeaderCard extends StatelessWidget {
  final SubmissionDetailDto detail;
  final String scoringMode;

  const HeaderCard({super.key, required this.detail, required this.scoringMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVoided = detail.status == 'voided';
    final scoreColor = _scoreColor(detail.totalScore, theme);
    final scoreText = ScoreFormatter.format(
      scoringMode: detail.scoringMode ?? scoringMode,
      rawEarned: detail.rawEarnedPoints,
      rawMax: detail.rawMaxPoints,
      totalScore: detail.totalScore,
      isWeighted: detail.isWeighted,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    detail.templateTitle ?? 'Audit',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(theme, isVoided),
              ],
            ),
            const SizedBox(height: 10),

            // Meta rows
            MetaRow(
              icon: Icons.store_outlined,
              label: detail.storeName ?? '—',
            ),
            MetaRow(
              icon: Icons.person_outline,
              label: detail.auditorName ?? '—',
            ),
            MetaRow(
              icon: Icons.calendar_today_outlined,
              label: isVoided
                  ? 'Voided ${_fmt(detail.voidedAt)}'
                  : 'Completed ${_fmt(detail.completedAt)}',
            ),

            // Void reason
            if (isVoided && detail.voidReason != null) ...[
              const SizedBox(height: 6),
              MetaRow(
                icon: Icons.info_outline,
                label: 'Reason: ${detail.voidReason}',
                color: theme.colorScheme.error,
              ),
            ],

            // Score
            if (!isVoided && scoreText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Score (${_formatMode(scoringMode)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    scoreText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ThemeData theme, bool isVoided) {
    final String label;
    final Color bg;
    final Color fg;

    if (isVoided) {
      label = 'VOIDED';
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
    } else {
      label = 'COMPLETED';
      bg = AppTheme.success.withAlpha(30);
      fg = AppTheme.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Color _scoreColor(double? score, ThemeData theme) {
    if (score == null) return theme.colorScheme.onSurface;
    if (score >= 90) return AppTheme.success;
    if (score >= 70) return AppTheme.warning;
    return theme.colorScheme.error;
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy HH:mm').format(dt.toLocal());
  }

  String _formatMode(String mode) {
    if (mode.isEmpty) return 'Penalty';
    return mode[0].toUpperCase() + mode.substring(1).toLowerCase();
  }
}

class MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const MetaRow({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: effectiveColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
