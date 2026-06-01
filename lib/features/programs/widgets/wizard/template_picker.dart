import 'package:flutter/material.dart';

import '../../../templates/managers/template_manager.dart';
import '../../../templates/models/template_dto.dart';

// SC-4: Extracted from program_wizard_steps.dart
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
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Select Template',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        
        Flexible(
          child: ListenableBuilder(
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
    ),
    ),
      ],
    );
  }
}
