import 'package:flutter/material.dart';

import '../../templates/models/template_dto.dart';
import '../model/answer_dto.dart';
import 'read_only_criterion_row.dart';

class AuditPreviewGroupBuilder extends StatelessWidget {
  final GroupDto group;
  final Map<String, AnswerDto> answersMap;
  final String scoringMode;
  final int depth;

  const AuditPreviewGroupBuilder({
    super.key,
    required this.group,
    required this.answersMap,
    required this.scoringMode,
    this.depth = 0,
  });

  bool _groupHasAnswers(GroupDto group, Map<String, AnswerDto> answersMap) {
    if (group.criteria.any((c) => answersMap.containsKey(c.id))) return true;
    if (group.children.any((child) => _groupHasAnswers(child, answersMap))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_groupHasAnswers(group, answersMap)) return const SizedBox.shrink();

    if (depth == 0) {
      // Top-level Visual Folder / Area (e.g., "H - Hospitality")
      // Render as a bold header, followed by its children
      final topLevelCriteria = group.criteria
          .where((c) => answersMap.containsKey(c.id))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
            child: Text(
              group.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // Directly render criteria if any exist at level 0
          if (topLevelCriteria.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              color: theme.colorScheme.surface,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < topLevelCriteria.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ReadOnlyCriterionRow(
                        answer: answersMap[topLevelCriteria[i].id]!,
                        criterion: topLevelCriteria[i],
                        scoringMode: scoringMode,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Render children
          ...group.children
              .where((child) => _groupHasAnswers(child, answersMap))
              .map(
                (child) => AuditPreviewGroupBuilder(
                  group: child,
                  answersMap: answersMap,
                  scoringMode: scoringMode,
                  depth: depth + 1,
                ),
              ),
        ],
      );
    } else {
      // Depth >= 1 (e.g., "H1", "H2")
      // Render as a single static Card containing the title and criteria
      final matchingCriteria = group.criteria
          .where((c) => answersMap.containsKey(c.id))
          .toList();

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        color: theme.colorScheme.surface,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Text(
                group.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Criteria Rows
            for (var i = 0; i < matchingCriteria.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ReadOnlyCriterionRow(
                  answer: answersMap[matchingCriteria[i].id]!,
                  criterion: matchingCriteria[i],
                  scoringMode: scoringMode,
                ),
              ),
            ],
            // Nested children (if any)
            if (group.children.any(
              (child) => _groupHasAnswers(child, answersMap),
            )) ...[
              ...group.children
                  .where((child) => _groupHasAnswers(child, answersMap))
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: AuditPreviewGroupBuilder(
                        group: child,
                        answersMap: answersMap,
                        scoringMode: scoringMode,
                        depth: depth + 1,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );
    }
  }
}
