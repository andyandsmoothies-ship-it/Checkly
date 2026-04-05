import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../models/template_dto.dart';
import 'criterion_row.dart';

// ---------------------------------------------------------------------------
// Helper: recursively count all criteria under a group tree
// ---------------------------------------------------------------------------
int _totalCriteriaCount(GroupDto group) {
  return group.criteria.length +
      group.children.fold(
        0,
        (sum, child) => sum + _totalCriteriaCount(child),
      );
}

/// Expandable section card that recursively renders sub-sections.
///
/// In the new Tab-Pagination layout, [SectionCard] is always called
/// with [depth] ≥ 1 (top-level sections are rendered as Tabs, not Cards).
/// Defaults to *collapsed* so the preview acts as a compressed Table of
/// Contents — auditors expand only what they care about.
class SectionCard extends StatelessWidget {
  final GroupDto group;
  final int depth;

  const SectionCard({super.key, required this.group, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;

    // Build subtitle: "X criteria • Y pts max"
    final criteriaCount = _totalCriteriaCount(group);
    final subtitleParts = <String>[];
    if (criteriaCount > 0) subtitleParts.add('$criteriaCount criteria');

    double? maxPts;
    if (group.metadata != null) {
      try {
        final meta = json.decode(group.metadata!) as Map<String, dynamic>;
        maxPts = (meta['subsection_max_points'] as num?)?.toDouble();
      } catch (_) {}
    }
    maxPts ??= group.maxDeductionPoints;
    if (maxPts != null) {
      subtitleParts.add('${maxPts.toStringAsFixed(0)} pts max');
    }

    final subtitleText =
        subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : null;

    return Container(
      margin: EdgeInsets.only(left: isRoot ? 0 : 12, bottom: isRoot ? 12 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRoot
              ? AppTheme.sageGray.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: isRoot ? 1 : 1.5,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Default collapsed — preview is a compressed Table of Contents
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          title: Row(
            children: [
              // Section title
              Expanded(
                child: Text(
                  group.title,
                  style: AppFonts.displayStyle(
                    fontSize: isRoot ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              // Info icon — on-demand section description (only when present)
              if (group.description != null &&
                  group.description!.isNotEmpty) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Section Description'),
                      content: SingleChildScrollView(
                        child: Text(group.description!),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ],

              // Weight badge (root sections only)
              if (group.weight != null && isRoot)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.weight!.toStringAsFixed(0)}%',
                    style: AppFonts.serifStyle(
                      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          // Dense summary: visible at a glance without expanding
          subtitle: subtitleText != null
              ? Text(
                  subtitleText,
                  style: AppFonts.serifStyle(
                    fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                    color: AppTheme.sageGray,
                  ),
                )
              : null,
          children: [
            // Criteria rows
            ...group.criteria.map((c) => CriterionRow(criterion: c)),

            // Nested sub-sections
            if (group.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  children: group.children
                      .map((g) => SectionCard(group: g, depth: depth + 1))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
