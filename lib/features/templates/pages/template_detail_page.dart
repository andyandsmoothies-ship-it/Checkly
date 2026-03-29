import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/template_manager.dart';
import 'widgets/overview_card.dart';
import 'widgets/section_card.dart';

final _di = GetIt.instance;

/// Template detail page — premium "Apothecary" read-only view.
///
/// Shows a template overview card with scoring rules summary,
/// then flat section cards with dense criteria rows.
class TemplateDetailPage extends StatefulWidget {
  final String templateId;

  const TemplateDetailPage({super.key, required this.templateId});

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<TemplateManager>().loadTemplateTree(widget.templateId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<TemplateManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Template Detail')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/stores/select?templateId=${widget.templateId}'),
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.play_arrow),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          if (manager.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final tree = manager.selectedTemplate.value;
          if (tree == null) {
            return Center(
              child: Text(
                manager.error ?? 'Template not found',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // 1. Overview card
              OverviewCard(tree: tree),
              const SizedBox(height: 20),

              // 2. Section cards
              ...tree.groups.map(
                (group) => SectionCard(group: group, depth: 0),
              ),
            ],
          );
        },
      ),
    );
  }
}
