import 'package:flutter/material.dart';

/// Wizard Step 1: Basic info — title, description, and type.
/// Mirrors MetadataFormCard but simplified for the guided flow.
class WizardStepName extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const WizardStepName({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedType,
    required this.onTypeChanged,
  });

  static const _types = [
    ('qc', 'Quality Control'),
    ('training', 'Training'),
    ('general', 'General'),
    ('task force', 'Task Force'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Name your template',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Give it a clear name so auditors know what they\'re completing.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),

        // Title field
        TextFormField(
          controller: titleCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Template Title *',
            hintText: 'e.g. Monthly Store Compliance Check',
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
        ),
        const SizedBox(height: 20),

        // Description field
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'What does this template check for?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 28),

        // Template type
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _types.map((t) {
            final isSelected = selectedType == t.$1;
            return ChoiceChip(
              label: Text(t.$2),
              selected: isSelected,
              onSelected: (_) => onTypeChanged(t.$1),
            );
          }).toList(),
        ),
      ],
    );
  }
}
