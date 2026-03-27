import 'package:flutter/material.dart';

import '../models/editable_group.dart';
import '../models/wizard_starter_packs.dart';

/// Wizard Step 2: Choose your structure.
/// Shows editable section titles and suggests new sections to add via Action Chips.
class WizardStepStructure extends StatefulWidget {
  final List<EditableGroup> sections;
  final String scoringMode;
  final VoidCallback onChanged;

  const WizardStepStructure({
    super.key,
    required this.sections,
    required this.scoringMode,
    required this.onChanged,
  });

  @override
  State<WizardStepStructure> createState() => _WizardStepStructureState();
}

class _WizardStepStructureState extends State<WizardStepStructure> {
  void _addSection(String title) {
    setState(() {
      final section = EditableGroup(title: title);
      section.titleCtrl.text = title;
      widget.sections.add(section);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions =
        WizardSuggestions.getSectionSuggestions(widget.scoringMode);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Build your structure',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Start by defining the main sections of your template. Add custom sections or tap suggestions below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Q2: empty state — shows when user hasn't added any sections yet
        if (widget.sections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.view_agenda_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sections yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sections are the main topics of your audit.\nAdd one above or pick from the suggestions below.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Sections List (when non-empty)
        else
          ...widget.sections.asMap().entries.map((e) {
            final i = e.key;
            final section = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: section.titleCtrl,
                      onChanged: (_) => widget.onChanged(),
                      decoration: InputDecoration(
                        labelText: 'Section ${i + 1}',
                        prefixIcon: const Icon(Icons.drag_indicator),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeSection(i),
                    tooltip: 'Remove section',
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addSection(''),
            icon: const Icon(Icons.add),
            label: const Text('Add Blank Section'),
          ),
        ),

        const Divider(height: 32),

        // Suggestions Block
        Text(
          'Suggested sections for this type:',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((title) {
            final alreadyAdded =
                widget.sections.any((s) => s.titleCtrl.text == title);
            return ActionChip(
              label: Text(title),
              avatar: const Icon(Icons.add, size: 16),
              onPressed: alreadyAdded ? null : () => _addSection(title),
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
        ),

        const SizedBox(height: 24),
        // Expert tip banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: A typical audit has 3–5 sections. You can add the specific questions (criteria) in the next step.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
