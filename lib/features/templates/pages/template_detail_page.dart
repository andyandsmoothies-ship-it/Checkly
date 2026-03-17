import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';

import '../manager/template_manager.dart';
import '../model/template_dto.dart';

final _di = GetIt.instance;

/// Template detail page — premium "Apothecary" read-only view.
///
/// Shows a template overview card with scoring rules summary,
/// then flat section cards with dense criteria rows.
class TemplateDetailPage extends StatefulWidget {
  final String templateId;

  const TemplateDetailPage({super.key, required this.templateId});

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<TemplateManager>().loadTemplateTree(widget.templateId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<TemplateManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Template Detail')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/stores/select?templateId=${widget.templateId}'),
        shape: const CircleBorder(),
        child: const Icon(Icons.play_arrow),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          if (manager.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final tree = manager.selectedTemplate.value;
          if (tree == null) {
            return Center(
              child: Text(
                manager.error ?? 'Template not found',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // 1. Overview card
              _OverviewCard(tree: tree),
              const SizedBox(height: 20),

              // 2. Section cards
              ...tree.groups.map(
                (group) => _SectionCard(group: group, depth: 0),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OVERVIEW CARD — template metadata + scoring rules summary
// ═══════════════════════════════════════════════════════════════

class _OverviewCard extends StatelessWidget {
  final TemplateTreeDto tree;
  const _OverviewCard({required this.tree});

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
                    color: AppTheme.charcoal,
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
            const SizedBox(height: 10),
            Text(
              tree.description!,
              style: AppFonts.displayStyle(
                fontSize: 14,
                color: AppTheme.charcoal.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],

          // Scoring rules badges
          if (rules.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: rules.map((r) => _RuleBadge(label: r)).toList(),
            ),
          ],

          // Stats row
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.layers_outlined,
                label: '${tree.groups.length} sections',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.checklist,
                label: '${_countAllCriteria(tree.groups)} criteria',
              ),
              const SizedBox(width: 12),
              _StatChip(icon: Icons.update, label: 'v${tree.version}'),
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
    switch (type) {
      case 'qc':
        return 'QC';
      case 'training':
        return 'TRAINING';
      default:
        return 'GENERAL';
    }
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

/// Small muted badge for scoring rules.
class _RuleBadge extends StatelessWidget {
  final String label;
  const _RuleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sageGray.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.sageGray.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppFonts.displayStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.charcoal.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Tiny stat chip with icon + label.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.sageGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.displayStyle(
            fontSize: 12,
            color: AppTheme.charcoal.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION CARD — flat card with criteria rows (recursive)
// ═══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final GroupDto group;
  final int depth;

  const _SectionCard({required this.group, required this.depth});

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
            ...group.criteria.map((c) => _CriterionRow(criterion: c)),

            // Nested sub-sections
            if (group.children.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  children: group.children
                      .map((g) => _SectionCard(group: g, depth: depth + 1))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CRITERION ROW — dense, flat row with badges aligned right
// ═══════════════════════════════════════════════════════════════

class _CriterionRow extends StatelessWidget {
  final CriterionDto criterion;

  const _CriterionRow({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bullet
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.sageGray.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),

              // Label
              Expanded(
                child: Text(
                  criterion.label,
                  style: AppFonts.displayStyle(
                    fontSize: 13,
                    color: AppTheme.charcoal.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ),

              // Points badge
              if (criterion.pointsWeight != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${criterion.pointsWeight!.toStringAsFixed(1)} pts',
                  style: AppFonts.serifStyle(
                    fontSize: 12,
                    color: AppTheme.charcoal.withValues(alpha: 0.45),
                  ),
                ),
              ],

              // CCP badge
              if (criterion.isCcp) ...[
                const SizedBox(width: 6),
                _FlagBadge(label: 'CCP', color: AppTheme.warning),
              ],

              // RISK badge
              if (criterion.isRisk) ...[
                const SizedBox(width: 6),
                _FlagBadge(label: 'RISK', color: theme.colorScheme.error),
              ],
            ],
          ),

          // Description (QC templates show the standard/requirement)
          if (criterion.description != null &&
              criterion.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 2),
              child: Text(
                criterion.description!,
                style: AppFonts.displayStyle(
                  fontSize: 11,
                  color: AppTheme.charcoal.withValues(alpha: 0.4),
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FLAG BADGE — small CCP/RISK pill
// ═══════════════════════════════════════════════════════════════

class _FlagBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _FlagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppFonts.displayStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
