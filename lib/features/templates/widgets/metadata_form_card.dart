import 'package:flutter/material.dart';

import '../../../_shared/widgets/section_header.dart';

import '../models/template_constants.dart';

class MetadataFormCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final String scoringMode;
  final ValueChanged<String?> onScoringModeChanged;

  const MetadataFormCard({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.scoringMode,
    required this.onScoringModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('TEMPLATE METADATA'),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Template Title',
                hintText: 'e.g. Weekly Food Safety Check',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what this template audits',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  TemplateConstants.categoryTypes.any((t) => t.$1 == type)
                  ? type
                  : 'qc',
              decoration: const InputDecoration(labelText: 'Category'),
              borderRadius: BorderRadius.circular(12),
              items: TemplateConstants.categoryTypes
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: scoringMode,
              decoration: InputDecoration(
                labelText: 'Scoring Mode',
                helperText: switch (scoringMode) {
                  'penalty' =>
                    '💡 How it works: Your audit starts with a perfect score. Each fault deducts points. Use Pass/Fail or Fault Count inputs for best results.',
                  'accumulation' =>
                    '💡 How it works: Your audit starts at zero. Each correct answer adds points. Use Scored Choices or Scale inputs for best results.',
                  'checklist' =>
                    '✅ How it works: Simple pass/fail compliance checks with no point scoring. The report shows compliance status for each item.',
                  'survey' =>
                    '📊 How it works: Collect responses without scoring. Results are aggregated for analysis. Use Single Choice or Multi Choice inputs.',
                  _ => '💡 Select a scoring mode to see how it works.',
                },
                helperMaxLines: 3,
              ),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(
                  value: 'penalty',
                  child: Text('Penalty (Top-Down)'),
                ),
                DropdownMenuItem(
                  value: 'accumulation',
                  child: Text('Accumulation (Zero-to-Top)'),
                ),
                DropdownMenuItem(
                  value: 'checklist',
                  child: Text('Checklist (Pass/Fail)'),
                ),
                DropdownMenuItem(
                  value: 'survey',
                  child: Text('Survey (No Scoring)'),
                ),
              ],
              onChanged: onScoringModeChanged,
            ),
          ],
        ),
      ),
    );
  }
}
