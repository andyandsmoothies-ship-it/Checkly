import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/template_manager.dart';
import '../model/template_dto.dart';

final _di = GetIt.instance;

/// Template detail page — shows the nested tree (sections → subsections → criteria).
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
    _di<TemplateManager>().loadTemplateTree(widget.templateId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<TemplateManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Template Detail')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/stores/select?templateId=${widget.templateId}'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Audit'),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // Header
              Text(
                tree.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tree.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  tree.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Sections
              ...tree.groups.map(
                (group) => _GroupSection(group: group, depth: 0),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Expandable group section — recursive for nested subsections.
class _GroupSection extends StatelessWidget {
  final GroupDto group;
  final int depth;

  const _GroupSection({required this.group, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(left: depth * 12.0, bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: depth == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (group.weight != null)
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
          // Criteria
          ...group.criteria.map((c) => _CriterionTile(criterion: c)),

          // Nested subsections
          ...group.children.map(
            (g) => _GroupSection(group: g, depth: depth + 1),
          ),
        ],
      ),
    );
  }
}

/// Criterion tile showing label, input type, and CCP/RISK flags.
class _CriterionTile extends StatelessWidget {
  final CriterionDto criterion;

  const _CriterionTile({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(criterion.label, style: theme.textTheme.bodyMedium),
      subtitle: Row(
        children: [
          _InputTypeBadge(inputType: criterion.inputType),
          if (criterion.isCcp) ...[
            const SizedBox(width: 6),
            _FlagBadge(label: 'CCP', color: AppTheme.warning),
          ],
          if (criterion.isRisk) ...[
            const SizedBox(width: 6),
            _FlagBadge(label: 'RISK', color: theme.colorScheme.error),
          ],
          if (criterion.pointsWeight != null) ...[
            const SizedBox(width: 6),
            Text(
              '${criterion.pointsWeight!.toStringAsFixed(1)} pts',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputTypeBadge extends StatelessWidget {
  final String inputType;
  const _InputTypeBadge({required this.inputType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        inputType.replaceAll('_', '/'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _FlagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
