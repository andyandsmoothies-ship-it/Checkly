import 'package:flutter/material.dart';
import 'package:checkly/_shared/widgets/primitives/stroke_card.dart';

import '../../../_shared/widgets/section_header.dart';

import '../models/template_constants.dart';

class MetadataFormCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController categoryTagCtrl;
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final String scoreDirection;
  final ValueChanged<String> onScoreDirectionChanged;
  final bool isWeighted;
  final ValueChanged<bool> onIsWeightedChanged;

  const MetadataFormCard({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.categoryTagCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.scoreDirection,
    required this.onScoreDirectionChanged,
    required this.isWeighted,
    required this.onIsWeightedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StrokeCard(
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
            initialValue: () {
              final normalized = type.toLowerCase().trim().replaceAll('_', ' ').replaceAll('taskforce', 'task force');
              return TemplateConstants.categoryTypes.any((t) => t.$1 == normalized)
                  ? normalized
                  : 'qc';
            }(),
            decoration: const InputDecoration(labelText: 'Category'),
            borderRadius: BorderRadius.circular(12),
            items: TemplateConstants.categoryTypes
                .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                .toList(),
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 16),
          const Text(
            'Score Direction',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'down',
                  label: Text('Penalty (Down)'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<String>(
                  value: 'up',
                  label: Text('Accumulation (Up)'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment<String>(
                  value: 'none',
                  label: Text('Survey (None)'),
                  icon: Icon(Icons.assessment),
                ),
              ],
              selected: {scoreDirection},
              onSelectionChanged: (Set<String> selection) {
                onScoreDirectionChanged(selection.first);
              },
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Weighted Scoring'),
            subtitle: const Text('💡 Distribute scoring impact using section/criteria weights.'),
            contentPadding: EdgeInsets.zero,
            value: scoreDirection == 'none' ? false : isWeighted,
            onChanged: scoreDirection == 'none'
                ? null
                : (val) => onIsWeightedChanged(val),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              switch (scoreDirection) {
                'none' =>
                  '📊 Survey: Collect responses without scoring. Results are aggregated for analysis. Use Single Choice or Multi Choice inputs.',
                'up' =>
                  '💡 Accumulation: Your audit starts at 0%. Points are added for compliant answers. Displays the final score as a percentage of total earned points over possible points.',
                'down' when isWeighted =>
                  '💡 Penalty (Weighted): Your audit starts at 100%. Faults deduct points from sections, which are then combined using section weights to calculate the final weighted percentage.',
                'down' when !isWeighted =>
                  '✅ Checklist (Simple Down): Simple pass/fail checks. Your audit starts at 100 points, and each failed item deducts its points weight directly. Displays total score and compliance status.',
                _ => '💡 Select a scoring mode to see how it works.',
              },
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: categoryTagCtrl,
            decoration: const InputDecoration(
              labelText: 'Category Tag',
              hintText: 'e.g. food_safety, cleanliness',
              helperText: 'A tag used to group and filter compliance audits.',
            ),
          ),
        ],
      ),
    );
  }
}
