import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../../_shared/widgets/section_header.dart';
import '../../../audit/model/submission_dto.dart';
import '../../../audit/services/draft_service.dart';
import '../../../auth/manager/auth_manager.dart';
import '../../manager/dashboard_manager.dart';

// ────────────────────────────────────────────────────────────────
// Submission Feed Section
// ────────────────────────────────────────────────────────────────

/// Recent submissions feed section — shared across all dashboard variants.
class SubmissionFeedSection extends StatelessWidget {
  final List<SubmissionDto> submissions;
  final BuildContext context;
  final ThemeData? theme;

  const SubmissionFeedSection({
    required this.submissions,
    required this.context,
    this.theme,
    super.key,
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
              onTap: () => context.findAncestorWidgetOfExactType<Scaffold>() != null
                  ? Navigator.of(context).pushNamed('/activity')
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                // WCAG tap target fix: raised from h:4,v:2 → h:12,v:12 (44px minimum)
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            (sub) => SubmissionRow(submission: sub, context: context),
          ),
      ],
    );
  }
}

/// Single submission row in the feed.
@visibleForTesting
class SubmissionRow extends StatefulWidget {
  final SubmissionDto submission;
  final BuildContext context;

  const SubmissionRow({required this.submission, required this.context, super.key});

  @override
  State<SubmissionRow> createState() => _SubmissionRowState();
}

class _SubmissionRowState extends State<SubmissionRow> {
  final _di = GetIt.instance;

  Future<void> _discardDraft() async {
    final sub = widget.submission;
    final tId = sub.templateId;
    final sId = sub.storeId;
    if (tId == null || sId == null) return;

    final userId = _di<AuthManager>().currentUser?.userId ?? 'anon';
    final draftKey = '$tId:$sId:$userId';

    await _di<DraftService>().deleteDraft(draftKey);
    await _di<DashboardManager>().loadStats();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft discarded')),
      );
    }
  }

  void _resumeDraft() {
    final sub = widget.submission;
    final tId = sub.templateId;
    final sId = sub.storeId;
    if (tId == null || sId == null) return;
    widget.context.findAncestorWidgetOfExactType<Scaffold>();
    Navigator.of(widget.context).pushNamed(
      '/audit',
      arguments: {'templateId': tId, 'storeId': sId, 'autoResume': true, 'submissionId': sub.id},
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final sub = widget.submission;
    final score = sub.totalScore;
    final isDraft = sub.status == 'draft';
    final scoreColor = theme.colorScheme.onSurface;
    final semanticColor = score != null
        ? (score >= 80
            ? AppColors.success
            : score >= 60
                ? AppColors.warning
                : AppColors.destructive)
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDraft
            ? _resumeDraft
            : () => Navigator.of(widget.context).pushNamed('/activity'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.templateTitle ?? 'Audit',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.storeName ?? 'Unknown'} · ${timeAgo(sub.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right side: for drafts show actions menu; otherwise score badge
              if (isDraft)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'resume') _resumeDraft();
                    if (value == 'discard') _discardDraft();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Resume Audit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'discard',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Discard Draft'),
                        ],
                      ),
                    ),
                  ],
                )
              else if (score != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: semanticColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: AppFonts.serifStyle(
                        fontSize: 18,
                        color: scoreColor,
                      ),
                    ),
                  ],
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
                    sub.status.toUpperCase(),
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
