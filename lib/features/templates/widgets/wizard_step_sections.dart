import 'package:flutter/material.dart';

import '../models/editable_criterion.dart';
import '../models/editable_group.dart';

/// Wizard Step 2: Add sections and criteria.
/// Simplified — no sub-sections, smart defaults for input type.
class WizardStepSections extends StatefulWidget {
  final List<EditableGroup> sections;
  final String scoringMode;
  final VoidCallback onChanged;

  const WizardStepSections({
    super.key,
    required this.sections,
    required this.scoringMode,
    required this.onChanged,
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

  void _addSection() {
    setState(() {
      widget.sections.add(
        EditableGroup(title: 'Section ${widget.sections.length + 1}'),
      );
    });
    widget.onChanged();
  }

  void _removeSection(int index) {
    setState(() {
      widget.sections[index].dispose();
      widget.sections.removeAt(index);
    });
    widget.onChanged();
  }

  void _addCriterion(EditableGroup section) {
    setState(() {
      section.criteria.add(
        EditableCriterion(inputType: _defaultInputType, points: '10'),
      );
    });
    widget.onChanged();
  }

  void _removeCriterion(EditableGroup section, int ci) {
    setState(() {
      section.criteria[ci].dispose();
      section.criteria.removeAt(ci);
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Build your sections',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add at least one section with criteria. You can always refine in the full editor later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Section cards
        ...widget.sections.asMap().entries.map((entry) {
          final si = entry.key;
          final section = entry.value;
          return _SectionCard(
            section: section,
            sectionIndex: si,
            scoringMode: widget.scoringMode,
            defaultInputType: _defaultInputType,
            onRemove: () => _removeSection(si),
            onAddCriterion: () => _addCriterion(section),
            onRemoveCriterion: (ci) => _removeCriterion(section, ci),
            onChanged: widget.onChanged,
          );
        }),

        const SizedBox(height: 12),
        // Add section button
        OutlinedButton.icon(
          onPressed: _addSection,
          icon: const Icon(Icons.add),
          label: const Text('Add Section'),
        ),

        if (widget.sections.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'At least one section is required.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Section card ──

class _SectionCard extends StatelessWidget {
  final EditableGroup section;
  final int sectionIndex;
  final String scoringMode;
  final String defaultInputType;
  final VoidCallback onRemove;
  final VoidCallback onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback onChanged;

  const _SectionCard({
    required this.section,
    required this.sectionIndex,
    required this.scoringMode,
    required this.defaultInputType,
    required this.onRemove,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: section.titleCtrl,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      labelText: 'Section ${sectionIndex + 1} Name',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove section',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Criteria
            if (section.criteria.isEmpty)
              Text(
                'No criteria yet. Tap "Add Criterion" below.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ...section.criteria.asMap().entries.map((ce) {
              final ci = ce.key;
              final criterion = ce.value;
              return _CriterionRow(
                criterion: criterion,
                index: ci,
                scoringMode: scoringMode,
                onRemove: () => onRemoveCriterion(ci),
                onChanged: onChanged,
              );
            }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAddCriterion,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Criterion'),
            ),
          ],
        ),
      ),
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
