import 'package:flutter/material.dart';

import '../models/wizard_starter_packs.dart';

/// Wizard Step 2: Choose your structure.
///
/// Renders the starter pack sections as toggleable cards. Users can:
/// - Enable/disable sections (disabled = excluded from Step 3)
/// - Rename a section inline
/// - Expand a section to preview criteria labels
/// - Add a custom blank section
class WizardStepStructure extends StatefulWidget {
  final List<StarterSection> sections;
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
  final _expandedSections = <int>{};

  void _toggleEnabled(int index) {
    setState(() {
      widget.sections[index].enabled = !widget.sections[index].enabled;
    });
    widget.onChanged();
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections.add(index);
      }
    });
  }

  void _addCustomSection() {
    setState(() {
      widget.sections.add(
        StarterSection(
          title: 'Section ${widget.sections.length + 1}',
          criteria: [],
        ),
      );
    });
    widget.onChanged();
  }

  void _showRenameDialog(int index) {
    final ctrl = TextEditingController(text: widget.sections[index].title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Section'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Section name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() => widget.sections[index].title = newName);
                widget.onChanged();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Choose your structure',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve pre-built a structure for you. Toggle sections on or off and rename them to match your needs.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Expert tip banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Audits work best with 3–5 sections and 5–10 criteria each.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section cards
        ...widget.sections.asMap().entries.map((entry) {
          final i = entry.key;
          final section = entry.value;
          final isExpanded = _expandedSections.contains(i);
          return _SectionToggleCard(
            section: section,
            sectionIndex: i,
            isExpanded: isExpanded,
            onToggleEnabled: () => _toggleEnabled(i),
            onToggleExpanded: () => _toggleExpanded(i),
            onRename: () => _showRenameDialog(i),
          );
        }),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addCustomSection,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Section'),
        ),

        if (widget.sections.every((s) => !s.enabled))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'At least one section must be enabled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _SectionToggleCard extends StatelessWidget {
  final StarterSection section;
  final int sectionIndex;
  final bool isExpanded;
  final VoidCallback onToggleEnabled;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRename;

  const _SectionToggleCard({
    required this.section,
    required this.sectionIndex,
    required this.isExpanded,
    required this.onToggleEnabled,
    required this.onToggleExpanded,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = section.enabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isEnabled ? 1 : 0,
      color: isEnabled
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Checkbox(
              value: isEnabled,
              onChanged: (_) => onToggleEnabled(),
            ),
            title: Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            subtitle: Text(
              '${section.criteria.length} criteria',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEnabled)
                  TextButton(
                    onPressed: onRename,
                    child: const Text('Rename'),
                  ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: onToggleExpanded,
                  tooltip: isExpanded ? 'Collapse' : 'Preview criteria',
                ),
              ],
            ),
          ),
          if (isExpanded && section.criteria.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: section.criteria
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.label,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
