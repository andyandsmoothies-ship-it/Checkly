import 'package:flutter/material.dart';

import '../../services/program_api_service.dart';
import '../../../../../_shared/theme/app_fonts.dart';

/// Dialog showing submitted evidence for a single program assignment.
///
/// Displays the text note and an optional photo URL for each evidence item.
/// Used by HQ reviewers tapping into a "Submitted" assignment in [ProgramDashboardPage].
class ProgramEvidenceViewerDialog extends StatelessWidget {
  final ProgramAssignmentDetailDto assignment;

  const ProgramEvidenceViewerDialog({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.storeName,
                      style: theme.textTheme.titleMedium?.merge(
                        AppFonts.displayStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // ── Evidence list ──
            Flexible(
              child: assignment.evidence.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No evidence items submitted.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: assignment.evidence.length,
                      separatorBuilder: (ctx, idx) => const Divider(height: 24),
                      itemBuilder: (context, i) {
                        final ev = assignment.evidence[i];
                        return _EvidenceItem(evidence: ev);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceItem extends StatelessWidget {
  final ProgramEvidenceDto evidence;

  const _EvidenceItem({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Criteria label
        Text(
          evidence.criteriaLabel.isNotEmpty
              ? evidence.criteriaLabel
              : 'Evidence',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        // Text value
        Text(evidence.value, style: theme.textTheme.bodyMedium),
        // Photo (if present)
        if (evidence.photoUrl != null && evidence.photoUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              evidence.photoUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                height: 80,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Submitted: ${evidence.createdAt.toLocal().toString().substring(0, 16)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
