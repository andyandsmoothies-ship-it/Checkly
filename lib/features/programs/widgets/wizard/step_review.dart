import 'package:flutter/material.dart';

import '../../pages/program_create_wizard_page.dart';
import 'wizard_date_utils.dart';

// SC-4: Extracted from program_wizard_steps.dart
// _ReviewRow is kept private and colocated with StepReview (its only consumer).
class StepReview extends StatelessWidget {
  final ProgramDraft draft;

  const StepReview({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 4 of 4: Review',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Title', value: draft.title),
          _ReviewRow(
            label: 'Category',
            value: draft.category.isEmpty ? '—' : draft.category,
          ),
          _ReviewRow(
            label: 'Deadline',
            value: draft.deadline != null
                ? formatWizardDate(draft.deadline!)
                : 'Not set',
          ),
          _ReviewRow(
            label: 'Template',
            value: draft.templateTitle ?? 'Not set',
          ),
          _ReviewRow(
            label: 'Stores',
            value: '${draft.storeIds.length} store(s)',
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
