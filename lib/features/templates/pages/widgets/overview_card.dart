import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../models/template_dto.dart';
import 'rich_description.dart';
import 'rule_badge.dart';
import 'stat_chip.dart';

/// Template metadata + scoring rules overview card.
class OverviewCard extends StatelessWidget {
  final TemplateTreeDto tree;
  const OverviewCard({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse scoring logic config
    final rules = _parseScoringRules(tree.scoringLogicConfig);
    final typeLabel = _typeLabel(tree.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tree.title,
                  style: AppFonts.serifStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: AppFonts.displayStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          // Description
          if (tree.description != null &&
              tree.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            RichDescription(description: tree.description!),
          ],

          // Scoring rules badges
          if (rules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: rules.map((r) => RuleBadge(label: r)).toList(),
            ),
          ],

          // Stats row
          const SizedBox(height: 16),
          Row(
            children: [
              StatChip(
                icon: Icons.layers_outlined,
                label: '${tree.groups.length} sections',
              ),
              const SizedBox(width: 12),
              StatChip(
                icon: Icons.checklist,
                label: '${_countAllCriteria(tree.groups)} criteria',
              ),
              const SizedBox(width: 12),
              StatChip(icon: Icons.update, label: 'v${tree.version}'),
            ],
          ),

          // Survey results button (survey mode only)
          if (rules.contains('Survey Mode')) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/survey-results/${tree.id}'),
                icon: const Icon(Icons.poll_outlined, size: 18),
                label: const Text('View Survey Results'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'qc' => 'QC',
      'training' => 'TRAINING',
      'general' => 'GENERAL',
      _ => type.toUpperCase(),
    };
  }

  List<String> _parseScoringRules(String? config) {
    if (config == null || config.isEmpty) return [];
    try {
      final map = json.decode(config) as Map<String, dynamic>;
      final rules = <String>[];
      // Scoring mode badge (primary identifier)
      final mode = map['scoringMode'] as String? ?? 'penalty';
      rules.add(switch (mode) {
        'accumulation' => 'Accumulation Mode',
        'checklist' => 'Checklist Mode',
        'survey' => 'Survey Mode',
        _ => 'Penalty Mode',
      });
      if (map['ccpOverride'] == true) rules.add('CCP Override');
      if (map['riskOverride'] == true) rules.add('Risk Multipliers');
      if (map['weightedDensity'] == true) rules.add('Weighted Density');
      if (map['confirmCorrect'] == true) rules.add('Confirm Correct');
      if (map['progressiveRepeatPenalty'] == true) {
        rules.add('Progressive Penalty');
      }
      return rules;
    } catch (_) {
      return [];
    }
  }

  int _countAllCriteria(List<GroupDto> groups) {
    var count = 0;
    for (final g in groups) {
      count += g.criteria.length;
      count += _countAllCriteria(g.children);
    }
    return count;
  }
}
