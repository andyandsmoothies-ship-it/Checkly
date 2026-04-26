import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../model/submission_dto.dart';
import 'audit_card.dart';

class StoreGroup extends StatelessWidget {
  final String storeName;
  final List<SubmissionDto> submissions;
  final void Function(SubmissionDto)? onStartAudit;
  final void Function(SubmissionDto)? onVoidAudit;
  final void Function(SubmissionDto)? onPreviewAudit;

  const StoreGroup({
    super.key,
    required this.storeName,
    required this.submissions,
    this.onStartAudit,
    this.onVoidAudit,
    this.onPreviewAudit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              storeName.toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                fontWeight: FontWeight.w700,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${submissions.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: submissions
            .map(
              (s) => AuditCard(
                submission: s,
                onStartAudit:
                    this.onStartAudit != null && ((s.status == 'scheduled' && !s.isOverdue) ||
                        s.status == 'draft')
                    ? () => onStartAudit?.call(s)
                    : null,
                onVoidAudit: (this.onVoidAudit != null && (s.status == 'draft' || s.status == 'scheduled'))
                    ? () => onVoidAudit?.call(s)
                    : null,
                onPreviewAudit:
                    (this.onPreviewAudit != null && (s.status == 'completed' || s.status == 'voided'))
                    ? () => onPreviewAudit?.call(s)
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}
