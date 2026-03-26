import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';
import '../models/editable_group.dart';
import '../models/wizard_starter_packs.dart';

/// Wizard Step 3: Build criteria per section.
/// Shows ONE section at a time with pill navigation at the top.
/// Simplified — no sub-sections, smart defaults for input type.
class WizardStepSections extends StatefulWidget {
  final List<EditableGroup> sections;
  final String scoringMode;
  final int currentSectionIndex;
  final VoidCallback onChanged;
  final ValueChanged<int> onSectionChanged;

  const WizardStepSections({
    super.key,
    required this.sections,
    required this.scoringMode,
    required this.currentSectionIndex,
    required this.onChanged,
    required this.onSectionChanged,
  });

  @override
  State<WizardStepSections> createState() => _WizardStepSectionsState();
}

class _WizardStepSectionsState extends State<WizardStepSections> {
  /// Default input type based on scoring mode.
  String get _defaultInputType {
    switch (widget.scoringMode) {
      case 'accumulation':
        return 'scale';
      case 'survey':
        return 'single_choice';
      case 'checklist':
      case 'penalty':
      default:
        return 'pass_fail';
    }
  }


  void _addCriterion() {
    final section = widget.sections[widget.currentSectionIndex];
    setState(() {
      section.criteria.add(
        EditableCriterion(inputType: _defaultInputType, points: '10'),
      );
    });
    widget.onChanged();
  }

  void _removeCriterion(int ci) {
    final section = widget.sections[widget.currentSectionIndex];
    setState(() {
      section.criteria[ci].dispose();
      section.criteria.removeAt(ci);
    });
    widget.onChanged();
  }

  void _showBatchAdd() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Batch Add Criteria',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter one criterion per line (max 20).',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 8,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Handwashing station available\nFloor cleanliness\nWaste disposal...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final lines = ctrl.text
                    .split('\n')
                    .map((l) => l.trim())
                    .where((l) => l.isNotEmpty)
                    .toList();
                final capped = lines.length > 20;
                final toAdd = lines.take(20).toList();
                final section = widget.sections[widget.currentSectionIndex];
                setState(() {
                  for (final label in toAdd) {
                    final c = EditableCriterion(
                      inputType: _defaultInputType,
                      points: '10',
                    );
                    c.labelCtrl.text = label;
                    section.criteria.add(c);
                  }
                });
                widget.onChanged();
                Navigator.pop(ctx);
                if (capped && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Maximum 20 criteria per batch. Additional lines were ignored.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Criteria'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionCount = widget.sections.length;
    final currentIdx = widget.currentSectionIndex.clamp(0, sectionCount - 1);

    if (sectionCount == 0) {
      return const Center(child: Text('No sections to build.'));
    }

    final section = widget.sections[currentIdx];

    return Column(
      children: [
        // Section pill navigation
        if (sectionCount > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                for (int i = 0; i < sectionCount; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        widget.sections[i].titleCtrl.text.isEmpty
                            ? 'Section ${i + 1}'
                            : widget.sections[i].titleCtrl.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: i == currentIdx,
                      onSelected: (_) => widget.onSectionChanged(i),
                    ),
                  ),
              ],
            ),
          ),

        // Criteria list for active section
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              // Section progress header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ${currentIdx + 1} of $sectionCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          section.titleCtrl.text.isEmpty
                              ? 'Section ${currentIdx + 1}'
                              : section.titleCtrl.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${section.criteria.length} criterion/criteria',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Batch add button
                  OutlinedButton.icon(
                    onPressed: _showBatchAdd,
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('Batch Add'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Criteria list
              if (section.criteria.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'No criteria yet. Tap "Add Criterion" or "Batch Add" below.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ...section.criteria.asMap().entries.map((ce) {
                final ci = ce.key;
                final criterion = ce.value;
                return _CriterionRow(
                  criterion: criterion,
                  index: ci,
                  scoringMode: widget.scoringMode,
                  onRemove: () => _removeCriterion(ci),
                  onChanged: widget.onChanged,
                );
              }),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCriterion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Blank Criterion'),
                ),
              ),
              
              const Divider(height: 32),
              
              Text(
                'Suggested criteria:',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (ctx) {
                  final suggestions = WizardSuggestions.getCriteriaSuggestions(
                      widget.scoringMode, section.titleCtrl.text);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((sc) {
                      final alreadyAdded = section.criteria
                          .any((c) => c.labelCtrl.text == sc.label);
                      return ActionChip(
                        label: Text(sc.label),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: alreadyAdded ? null : () {
                          setState(() {
                            final c = EditableCriterion(
                                inputType: sc.inputType, points: sc.points);
                            c.labelCtrl.text = sc.label;
                            section.criteria.add(c);
                          });
                          widget.onChanged();
                        },
                        backgroundColor: alreadyAdded
                            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                            : theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: alreadyAdded
                              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ── Criterion row (simplified) ──

const _inputTypes = [
  ('pass_fail', 'Pass / Fail'),
  ('numeric', 'Numeric Count'),
  ('scale', 'Scale (0–5)'),
  ('text', 'Text Note'),
  ('single_choice', 'Single Choice'),
  ('multi_choice', 'Multi Choice'),
];

class _CriterionRow extends StatefulWidget {
  final EditableCriterion criterion;
  final int index;
  final String scoringMode;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _CriterionRow({
    required this.criterion,
    required this.index,
    required this.scoringMode,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_CriterionRow> createState() => _CriterionRowState();
}

class _CriterionRowState extends State<_CriterionRow> {
  bool get _isScored =>
      widget.scoringMode != 'survey' &&
      widget.criterion.inputType != 'text' &&
      widget.criterion.inputType != 'single_choice' &&
      widget.criterion.inputType != 'multi_choice';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Criterion number
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 8),
            child: Text(
              '${widget.index + 1}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Label
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: widget.criterion.labelCtrl,
              onChanged: (_) => widget.onChanged(),
              decoration: const InputDecoration(
                labelText: 'Criterion label',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Input type
          DropdownMenu<String>(
            initialSelection: widget.criterion.inputType,
            width: 140,
            inputDecorationTheme: const InputDecorationTheme(isDense: true),
            label: const Text('Type'),
            dropdownMenuEntries: _inputTypes
                .map((t) => DropdownMenuEntry(value: t.$1, label: t.$2))
                .toList(),
            onSelected: (v) {
              if (v != null) {
                setState(() => widget.criterion.inputType = v);
                widget.onChanged();
              }
            },
          ),
          const SizedBox(width: 8),

          // Points (only for scored modes)
          if (_isScored)
            SizedBox(
              width: 56,
              child: TextFormField(
                controller: widget.criterion.pointsCtrl,
                onChanged: (_) => widget.onChanged(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pts',
                  isDense: true,
                ),
              ),
            ),

          // Remove
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onRemove,
            tooltip: 'Remove criterion',
          ),
        ],
      ),
    );
  }
}
