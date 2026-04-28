import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/widgets/section_header.dart';
import '../../../audit/model/submission_dto.dart';
import 'submission_row.dart';

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
              onTap: () => context.go('/activity'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                // WCAG tap target fix: raised from h:4,v:2 → h:12,v:12 (44px minimum)
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
