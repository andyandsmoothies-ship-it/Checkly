import 'package:flutter/material.dart';

import '../../pages/program_create_wizard_page.dart';

// SC-4: Extracted from program_wizard_steps.dart
class StepTemplate extends StatelessWidget {
  final ProgramDraft draft;
  final VoidCallback onPickTemplate;
  final VoidCallback onNext;

  const StepTemplate({
    super.key,
    required this.draft,
    required this.onPickTemplate,
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
            'Step 2 of 4: Select Template',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('program_template_button'),
            onPressed: onPickTemplate,
            icon: const Icon(Icons.description_outlined),
            label: Text(draft.templateTitle ?? 'Choose Template *'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            key: const Key('step_template_next_button'),
            onPressed: draft.templateId != null ? onNext : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
