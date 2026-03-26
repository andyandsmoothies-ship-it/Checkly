import 'package:flutter/material.dart';

/// Wizard Step 1: Basic info — title, description, and type.
/// Mirrors MetadataFormCard but simplified for the guided flow.
class WizardStepName extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String selectedType;
  final String scoringMode;
  final ValueChanged<String> onTypeChanged;

  const WizardStepName({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedType,
    required this.scoringMode,
    required this.onTypeChanged,
  });

  static String _hintText(String mode) => switch (mode) {
    'accumulation' => 'e.g. New Staff Onboarding Assessment',
    'survey'       => 'e.g. Customer Satisfaction Survey',
    'checklist'    => 'e.g. Daily Opening Checklist',
    _              => 'e.g. Monthly Store Compliance Audit',
  };

  static ({IconData icon, String title, String body}) _explainer(String mode) =>
      switch (mode) {
    'accumulation' => (
        icon: Icons.school_outlined,
        title: 'Training Assessment',
        body: 'Evaluates staff knowledge and performance. Points accumulate as criteria are met.',
      ),
    'survey' => (
        icon: Icons.sentiment_satisfied_outlined,
        title: 'Feedback Survey',
        body: 'Collects qualitative feedback without scoring. Ideal for customer or employee satisfaction.',
      ),
    'checklist' => (
        icon: Icons.checklist_outlined,
        title: 'Custom Checklist',
        body: 'A simple pass/fail checklist for recurring tasks. No complex scoring required.',
      ),
    _ => (
        icon: Icons.gpp_good_outlined,
        title: 'Compliance Audit',
        body: 'Measures conformance to standards. Deductions apply for each failed criterion.',
      ),
  };

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
          decoration: InputDecoration(
            labelText: 'Template Title *',
            hintText: _hintText(scoringMode),
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
        const SizedBox(height: 20),

        // Mode explainer
        Builder(builder: (context) {
          final theme = Theme.of(context);
          final ex = _explainer(scoringMode);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ex.icon, size: 22, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex.body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
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
