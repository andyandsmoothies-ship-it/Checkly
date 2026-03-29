import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../models/template_dto.dart';
import 'criterion_row.dart';

/// Expandable section card that recursively renders sub-sections.
class SectionCard extends StatelessWidget {
  final GroupDto group;
  final int depth;

  const SectionCard({super.key, required this.group, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;

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
          initiallyExpanded: true,
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
                    color: AppTheme.charcoal,
                  ),
                ),
              ),

              // Sub-section metadata (max points / minus per fault)
              if (!isRoot) ...[
                if (group.metadata != null) ...[
                  Builder(
                    builder: (context) {
                      try {
                        final meta =
                            json.decode(group.metadata!)
                                as Map<String, dynamic>;
                        final maxPts = meta['subsection_max_points'];
                        if (maxPts != null) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${maxPts}pt max',
                              style: AppFonts.serifStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Metadata display parse: $e');
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
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
