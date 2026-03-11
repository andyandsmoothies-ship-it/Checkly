import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/manager/template_manager.dart';
import '../../templates/model/template_dto.dart';
import '../manager/audit_manager.dart';

final _di = GetIt.instance;

/// Main audit form page — fills criteria answers and submits.
class AuditFormPage extends StatefulWidget {
  final String templateId;
  final String storeId;

  const AuditFormPage({
    super.key,
    required this.templateId,
    required this.storeId,
  });

  @override
  State<AuditFormPage> createState() => _AuditFormPageState();
}

class _AuditFormPageState extends State<AuditFormPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndStartAudit();
  }

  Future<void> _loadAndStartAudit() async {
    final templateManager = _di<TemplateManager>();
    await templateManager.loadTemplateTree(widget.templateId);
    final tree = templateManager.selectedTemplate.value;

    if (tree != null) {
      _di<AuditManager>().startAudit(tree, widget.storeId);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Audit...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final manager = _di<AuditManager>();

    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final template = manager.template;
        if (template == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Audit')),
            body: const Center(child: Text('Template not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(template.title, overflow: TextOverflow.ellipsis),
            actions: [
              _ScoreChip(score: manager.liveScore),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Live score HUD
              _ScoreHud(score: manager.liveScore),

              // Sections
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: template.groups.length,
                  itemBuilder: (context, i) =>
                      _SectionCard(group: template.groups[i], manager: manager),
                ),
              ),
            ],
          ),

          // Submit FAB
          floatingActionButton: FloatingActionButton.extended(
            onPressed: manager.isSubmitting ? null : () => _onSubmit(manager),
            icon: manager.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(manager.isSubmitting ? 'Submitting...' : 'Submit'),
          ),
        );
      },
    );
  }

  Future<void> _onSubmit(AuditManager manager) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Audit?'),
        content: Text(
          'Score: ${manager.liveScore.toStringAsFixed(2)}%\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await manager.submitAudit();

    if (mounted) {
      if (manager.lastSubmission != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit submitted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/home');
      } else if (manager.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(manager.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ============================================================
// Live Score HUD
// ============================================================

class _ScoreHud extends StatelessWidget {
  final double score;
  const _ScoreHud({required this.score});

  Color _scoreColor(ThemeData theme) {
    if (score >= 80) return AppTheme.success;
    if (score >= 50) return AppTheme.warning;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(theme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Score',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${score.toStringAsFixed(2)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              color: color,
              backgroundColor: color.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double score;
  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '${score.toStringAsFixed(1)}%',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ============================================================
// Section Card
// ============================================================

class _SectionCard extends StatelessWidget {
  final GroupDto group;
  final AuditManager manager;

  const _SectionCard({required this.group, required this.manager});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (group.weight != null && group.weight! > 0)
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
          ...group.criteria.map(
            (c) => _CriterionTile(criterion: c, manager: manager),
          ),
          ...group.children.map(
            (g) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _SectionCard(group: g, manager: manager),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Criterion Tile — answer input
// ============================================================

class _CriterionTile extends StatelessWidget {
  final CriterionDto criterion;
  final AuditManager manager;

  const _CriterionTile({required this.criterion, required this.manager});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = manager.answers[criterion.id];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + flags
          Row(
            children: [
              Expanded(
                child: Text(
                  criterion.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (criterion.isCcp) _Badge('CCP', AppTheme.warning),
              if (criterion.isRisk) _Badge('RISK', theme.colorScheme.error),
            ],
          ),
          const SizedBox(height: 8),

          // Input based on type
          if (criterion.inputType == 'pass_fail')
            _PassFailInput(
              value: answer?.value,
              onChanged: (v) => manager.setAnswer(criterion.id, value: v),
            )
          else
            _NumericInput(
              value: answer?.numericValue,
              onChanged: (v) =>
                  manager.setAnswer(criterion.id, numericValue: v),
            ),

          const SizedBox(height: 4),
          const Divider(),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// Input widgets
// ============================================================

class _PassFailInput extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const _PassFailInput({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'conform', label: Text('Conform')),
        ButtonSegment(value: 'non_conform', label: Text('Non-Conform')),
        ButtonSegment(value: 'na', label: Text('N/A')),
      ],
      selected: value != null ? {value!} : {},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
          theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NumericInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double> onChanged;

  const _NumericInput({this.value, required this.onChanged});

  @override
  State<_NumericInput> createState() => _NumericInputState();
}

class _NumericInputState extends State<_NumericInput> {
  late double _count;

  @override
  void initState() {
    super.initState();
    _count = widget.value ?? 0;
  }

  @override
  void didUpdateWidget(_NumericInput old) {
    super.didUpdateWidget(old);
    _count = widget.value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          'Faults:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: _count > 0
              ? () {
                  setState(() => _count = max(0, _count - 1));
                  widget.onChanged(_count);
                }
              : null,
          icon: const Icon(Icons.remove, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            _count.toInt().toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {
            setState(() => _count++);
            widget.onChanged(_count);
          },
          icon: const Icon(Icons.add, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
