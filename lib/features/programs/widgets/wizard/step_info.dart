import 'package:flutter/material.dart';

import '../../pages/program_create_wizard_page.dart';
import 'wizard_date_utils.dart';

// SC-4: Extracted from program_wizard_steps.dart
class StepInfo extends StatefulWidget {
  final ProgramDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onNext;

  const StepInfo({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<StepInfo> createState() => _StepInfoState();
}

class _StepInfoState extends State<StepInfo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.draft.title);
    _categoryCtrl = TextEditingController(text: widget.draft.category);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.draft.deadline ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      widget.draft.deadline = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
      widget.onChanged();
    }
  }

  void _saveAndNext() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.draft.title = _titleCtrl.text.trim();
      widget.draft.category = _categoryCtrl.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step 1 of 4: Campaign Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('program_title_field'),
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Campaign Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('program_category_field'),
              controller: _categoryCtrl,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('program_deadline_button'),
              onPressed: _pickDeadline,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                widget.draft.deadline != null
                    ? 'Deadline: ${formatWizardDate(widget.draft.deadline!)}'
                    : 'Set Deadline *',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              key: const Key('step_info_next_button'),
              onPressed: _saveAndNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
