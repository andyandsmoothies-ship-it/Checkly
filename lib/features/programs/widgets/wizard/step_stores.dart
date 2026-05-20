import 'package:flutter/material.dart';

import '../../pages/program_create_wizard_page.dart';

// SC-4: Extracted from program_wizard_steps.dart
class StepStores extends StatelessWidget {
  final ProgramDraft draft;
  final VoidCallback onPickStores;
  final VoidCallback onNext;

  const StepStores({
    super.key,
    required this.draft,
    required this.onPickStores,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 3 of 4: Select Stores',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('program_stores_button'),
            onPressed: onPickStores,
            icon: const Icon(Icons.store_outlined),
            label: Text(
              draft.storeIds.isEmpty
                  ? 'Select Stores *'
                  : '${draft.storeIds.length} store(s) selected',
            ),
          ),
          if (draft.storeIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Select at least 1 store.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            key: const Key('step_stores_next_button'),
            onPressed: draft.storeIds.isNotEmpty ? onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
