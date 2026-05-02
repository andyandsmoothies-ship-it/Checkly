import 'package:flutter/material.dart';
import '../../templates/models/template_dto.dart';
import '../model/answer_dto.dart';
import '../../../_shared/theme/app_theme.dart';

class _SectionStats {
  final GroupDto group;
  final double totalPoints;
  final int conformCount;
  final int nonConformCount;
  final int totalAnswered;
  final int totalCriteria;

  _SectionStats({
    required this.group,
    required this.totalPoints,
    required this.conformCount,
    required this.nonConformCount,
    required this.totalAnswered,
    required this.totalCriteria,
  });

  int get totalPassFail => conformCount + nonConformCount;
  double get passRate => totalPassFail == 0 ? 0 : conformCount / totalPassFail;
}

class DynamicSectionSummary extends StatelessWidget {
  final List<GroupDto> rootGroups;
  final Map<String, AnswerDto> answersMap;
  final String scoringMode;

  const DynamicSectionSummary({
    super.key,
    required this.rootGroups,
    required this.answersMap,
    required this.scoringMode,
  });

  _SectionStats _calculateStats(GroupDto group) {
    double totalPoints = 0;
    int conformCount = 0;
    int nonConformCount = 0;
    int totalAnswered = 0;
    int totalCriteria = 0;

    void traverse(GroupDto g) {
      totalCriteria += g.criteria.length;
      for (final c in g.criteria) {
        final answer = answersMap[c.id];
        if (answer != null) {
          if (answer.value != null) {
            totalAnswered++;
          }
          totalPoints += answer.numericValue ?? 0;
          if (answer.value == 'conform') {
            conformCount++;
          } else if (answer.value == 'non_conform') {
            nonConformCount++;
          }
        }
      }
      for (final child in g.children) {
        traverse(child);
      }
    }

    traverse(group);
    return _SectionStats(
      group: group,
      totalPoints: totalPoints,
      conformCount: conformCount,
      nonConformCount: nonConformCount,
      totalAnswered: totalAnswered,
      totalCriteria: totalCriteria,
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    _SectionStats stat,
    bool isWorst,
  ) {
    final theme = Theme.of(context);

    Widget valueWidget;
    Color? pillColor;
    Color? textColor;
    BoxBorder? pillBorder;

    if (scoringMode == 'pass_fail') {
      final rate = (stat.passRate * 100).round();
      if (rate == 100) {
        pillColor = AppTheme.success.withValues(alpha: 0.15);
        textColor = AppTheme.success;
      } else if (rate > 50) {
        pillColor = AppTheme.warning.withValues(alpha: 0.15);
        textColor = AppTheme.warning;
      } else {
        pillColor = theme.colorScheme.error.withValues(alpha: 0.15);
        textColor = theme.colorScheme.error;
      }
      valueWidget = Text(
        '$rate% Pass (${stat.conformCount}/${stat.totalPassFail})',
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (scoringMode == 'accumulation') {
      final pts = stat.totalPoints.toInt();
      pillColor = AppTheme.success.withValues(alpha: 0.15);
      textColor = AppTheme.success;
      valueWidget = Text(
        '+$pts pt${pts != 1 ? 's' : ''}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (scoringMode == 'survey') {
      pillColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant;
      valueWidget = Text(
        '${stat.totalAnswered}/${stat.totalCriteria} Answered',
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (scoringMode == 'checklist') {
      final faults = stat.totalPoints.toInt();
      if (faults > 0) {
        pillColor = theme.colorScheme.error.withValues(alpha: 0.15);
        textColor = theme.colorScheme.error;
        pillBorder = Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        );
      } else {
        pillColor = AppTheme.success.withValues(alpha: 0.15);
        textColor = AppTheme.success;
      }
      valueWidget = Text(
        '$faults Fault${faults != 1 ? 's' : ''}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Penalty mode
      final pts = stat.totalPoints.toInt();
      if (pts > 0) {
        pillColor = theme.colorScheme.error.withValues(alpha: 0.15);
        textColor = theme.colorScheme.error;
      } else {
        pillColor = AppTheme.success.withValues(alpha: 0.15);
        textColor = AppTheme.success;
      }
      valueWidget = Text(
        '-$pts pt${pts != 1 ? 's' : ''}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (isWorst) ...[
                  Icon(
                    scoringMode == 'accumulation'
                        ? Icons.info_outline
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: scoringMode == 'accumulation'
                        ? AppTheme.warning
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    stat.group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isWorst ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillColor,
              border: pillBorder,
              borderRadius: BorderRadius.circular(6),
            ),
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = rootGroups.map((g) => _calculateStats(g)).where((s) {
      if (scoringMode == 'pass_fail') return s.totalPassFail > 0;
      if (scoringMode == 'survey') return s.totalCriteria > 0;
      return s.totalPoints > 0 ||
          s.conformCount > 0 ||
          s.nonConformCount > 0 ||
          s.totalCriteria > 0;
    }).toList();

    if (stats.isEmpty) return const SizedBox.shrink();

    bool Function(_SectionStats) isWorst = (s) => false;
    if (scoringMode == 'pass_fail') {
      final worstRate = stats
          .map((s) => s.passRate)
          .reduce((a, b) => a < b ? a : b);
      isWorst = (s) => s.passRate == worstRate && s.nonConformCount > 0;
    } else if (scoringMode == 'accumulation') {
      final worstPts = stats
          .map((s) => s.totalPoints)
          .reduce((a, b) => a < b ? a : b);
      isWorst = (s) => s.totalPoints == worstPts && s.totalPoints > 0;
    } else if (scoringMode != 'survey') {
      final worstPts = stats
          .map((s) => s.totalPoints)
          .reduce((a, b) => a > b ? a : b);
      isWorst = (s) => s.totalPoints == worstPts && s.totalPoints > 0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Section Summary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...stats.map((s) => _buildSummaryRow(context, s, isWorst(s))),
          ],
        ),
      ),
    );
  }
}
