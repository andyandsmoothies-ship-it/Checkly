import 'package:flutter/material.dart';

import '../models/editable_group.dart';

class ReviewSectionBreakdown extends StatelessWidget {
  final List<EditableGroup> sections;
  final Set<int> expandedSections;
  final ValueChanged<int> onToggle;

  const ReviewSectionBreakdown({
    super.key,
    required this.sections,
    required this.expandedSections,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sections',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...sections.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isExpanded = expandedSections.contains(i);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onToggle(i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.titleCtrl.text.isEmpty
                                ? 'Section ${i + 1}'
                                : s.titleCtrl.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // BL-BADGE: dual-stat when sub-sections exist
                        Text(
                          s.subSections.isEmpty
                              ? '${s.countCriteria()} criteria'
                              : '${s.countCriteria()} criteria \u2022 ${s.subSections.length} sub-sections',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    // BL-NO-REGRESSION: root-only sections unchanged.
                    // BL-INDENT: sub-section titles at left:8, their criteria at left:24.
                    if (isExpanded &&
                        (s.criteria.isNotEmpty ||
                            s.subSections.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      // Root criteria
                      ...s.criteria.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.labelCtrl.text,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sub-sections with indented criteria
                      ...s.subSections.asMap().entries.map((subEntry) {
                        final si = subEntry.key;
                        final sub = subEntry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sub-section title row
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 2,
                                left: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right,
                                    size: 14,
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    sub.titleCtrl.text.isEmpty
                                        ? 'Sub-section ${si + 1}'
                                        : sub.titleCtrl.text,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' (${sub.criteria.length})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sub-section criteria (double-indented)
                            ...sub.criteria.map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 4,
                                  left: 24,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 4,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.labelCtrl.text,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
