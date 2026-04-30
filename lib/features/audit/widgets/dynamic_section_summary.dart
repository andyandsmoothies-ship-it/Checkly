import 'package:flutter/material.dart';
import '../../templates/models/template_dto.dart';
import '../model/answer_dto.dart';
import '../../../_shared/theme/app_theme.dart';

class _SectionStats {
  final GroupDto group;
  final double totalPoints;
  final int conformCount;
  final int nonConformCount;

  _SectionStats({
    required this.group,
    required this.totalPoints,
    required this.conformCount,
    required this.nonConformCount,
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

    void traverse(GroupDto g) {
      for (final c in g.criteria) {
        final answer = answersMap[c.id];
        if (answer != null) {
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
    );
  }

  Widget _buildSummaryRow(BuildContext context, _SectionStats stat, bool isWorst) {
    final theme = Theme.of(context);
    
    Widget valueWidget;
    if (scoringMode == 'pass_fail') {
      final rate = (stat.passRate * 100).round();
      valueWidget = Text(
        '$rate% Pass (${stat.conformCount}/${stat.totalPassFail})',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isWorst ? theme.colorScheme.error : null,
          fontWeight: isWorst ? FontWeight.bold : FontWeight.w600,
        ),
      );
    } else if (scoringMode == 'penalty') {
      final pts = stat.totalPoints.toInt();
      valueWidget = Text(
        '-$pts pt${pts != 1 ? 's' : ''}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isWorst ? theme.colorScheme.error : null,
          fontWeight: isWorst ? FontWeight.bold : FontWeight.w600,
        ),
      );
    } else {
      final pts = stat.totalPoints.toInt();
      valueWidget = Text(
        '+$pts pt${pts != 1 ? 's' : ''}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isWorst ? AppTheme.warning : null,
          fontWeight: isWorst ? FontWeight.bold : FontWeight.w600,
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
                    scoringMode == 'accumulation' ? Icons.info_outline : Icons.warning_amber_rounded,
                    size: 16,
                    color: scoringMode == 'accumulation' ? AppTheme.warning : theme.colorScheme.error,
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
          valueWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = rootGroups.map((g) => _calculateStats(g)).where((s) {
      if (scoringMode == 'pass_fail') return s.totalPassFail > 0;
      return s.totalPoints > 0 || s.conformCount > 0 || s.nonConformCount > 0;
    }).toList();

    if (stats.isEmpty) return const SizedBox.shrink();

    _SectionStats? worstSection;
    if (scoringMode == 'penalty') {
      worstSection = stats.reduce((curr, next) => curr.totalPoints > next.totalPoints ? curr : next);
      if (worstSection.totalPoints == 0) worstSection = null;
    } else if (scoringMode == 'pass_fail') {
      worstSection = stats.reduce((curr, next) => curr.passRate < next.passRate ? curr : next);
      if (worstSection.nonConformCount == 0) worstSection = null;
    } else if (scoringMode == 'accumulation') {
      worstSection = stats.reduce((curr, next) => curr.totalPoints < next.totalPoints ? curr : next);
      if (worstSection.totalPoints == 0) worstSection = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Section Summary',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...stats.map((s) => _buildSummaryRow(context, s, s == worstSection)),
          ],
        ),
      ),
    );
  }
}
