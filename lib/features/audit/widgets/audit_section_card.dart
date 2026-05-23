import 'package:flutter/material.dart';

import 'package:checkly/_shared/theme/app_fonts.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';
import 'audit_criterion_row.dart';

// ============================================================
// Section Card
// ============================================================

class AuditSectionCard extends StatelessWidget {
  final GroupDto group;
  final AuditManager manager;
  final int depth;
  final bool confirmRequired;
  final bool ccpEnabled;
  final bool riskEnabled;

  const AuditSectionCard({
    super.key,
    required this.group,
    required this.manager,
    this.depth = 0,
    this.confirmRequired = false,
    this.ccpEnabled = true,
    this.riskEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionScore = depth == 0 ? manager.sectionScores[group.id] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: AppFonts.displayStyle(
                  fontSize: depth == 0 ? 15 : 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Section score display (top-level only)
            if (depth == 0 && sectionScore != null) ...[
              if (sectionScore.hasCcpFailure)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CCP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sectionScore.hasCcpFailure
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sectionScore.score.toStringAsFixed(0)} / ${sectionScore.maxPoints.toStringAsFixed(0)} pts',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sectionScore.hasCcpFailure
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (depth == 0 &&
                group.weight != null &&
                group.weight! > 0 &&
                manager.liveScore != null) // Hide weight in Survey mode
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${group.weight!.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        children: [
          ...group.criteria.indexed.map(
            ((int, CriterionDto) entry) => AuditCriterionRow(
              criterion: entry.$2,
              manager: manager,
              confirmRequired: confirmRequired,
              ccpEnabled: ccpEnabled,
              riskEnabled: riskEnabled,
              index: entry.$1 + 1, // 1-based section-local display number
            ),
          ),
          ...group.children.map(
            (g) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: AuditSectionCard(
                group: g,
                manager: manager,
                depth: depth + 1,
                confirmRequired: confirmRequired,
                ccpEnabled: ccpEnabled,
                riskEnabled: riskEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
