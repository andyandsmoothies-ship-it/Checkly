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
              final normalized = type
                  .toLowerCase()
                  .trim()
                  .replaceAll('_', ' ')
                  .replaceAll('taskforce', 'task force');
              return TemplateConstants.categoryTypes.any(
                    (t) => t.$1 == normalized,
                  )
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
            subtitle: Text(
              scoreDirection == 'none'
                  ? '💡 Scoring is disabled for surveys.'
                  : (isWeighted
                        ? '💡 Sections and questions have different importance (weights) to calculate the score.'
                        : '💡 All sections and questions have equal importance in the final score.'),
            ),
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
                  '📊 Survey: Gather answers without calculating any scores. Used to collect general feedback.',
                'up' when isWeighted =>
                  '💡 Accumulation (Weighted): Your audit starts at 0%. You gain points for correct answers. Sections have different weights to calculate the final score.',
                'up' when !isWeighted =>
                  '💡 Accumulation: Your audit starts at 0%. You gain points for correct answers. Your final score is the percentage of points you earned out of the total possible.',
                'down' when isWeighted =>
                  '💡 Penalty (Weighted): Your audit starts at 100%. Failed items take points away from each section. The final score combines each section based on its importance (weight).',
                'down' when !isWeighted =>
                  '✅ Checklist (Simple Down): Simple pass/fail checks. Your audit starts at 100 points. Each failed item takes points away directly from the total score.',
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
