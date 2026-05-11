import 'package:flutter/material.dart';

import '../pages/program_create_wizard_page.dart';
import '../../templates/managers/template_manager.dart';
import '../../templates/models/template_dto.dart';

// ── Utility ────────────────────────────────────────────────────────────────────
String formatWizardDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

// ── Step 1: Info ───────────────────────────────────────────────────────────────
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
              'Step 1 of 4: Program Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('program_title_field'),
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Program Title *',
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

// ── Step 2: Template ───────────────────────────────────────────────────────────
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

// ── Step 3: Stores ─────────────────────────────────────────────────────────────
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

// ── Step 4: Review ─────────────────────────────────────────────────────────────
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

// ── Template Picker Bottom Sheet ───────────────────────────────────────────────
class TemplatePicker extends StatelessWidget {
  final TemplateManager templateManager;
  final void Function(TemplateDto) onSelected;

  const TemplatePicker({
    super.key,
    required this.templateManager,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: templateManager,
      builder: (context, _) {
        if (templateManager.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (templateManager.error != null) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(templateManager.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => templateManager.loadTemplates(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final templates = templateManager.templates.value;
        if (templates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No templates exist yet. Please create one first.'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: templates.length,
          itemBuilder: (ctx, i) {
            final t = templates[i];
            return ListTile(
              key: Key('template_item_${t.id}'),
              title: Text(t.title),
              subtitle: t.description != null ? Text(t.description!) : null,
              onTap: () => onSelected(t),
            );
          },
        );
      },
    );
  }
}
