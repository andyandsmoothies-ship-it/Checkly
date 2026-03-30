import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/template_manager.dart';
import 'widgets/criterion_row.dart';
import 'widgets/overview_card.dart';
import 'widgets/section_card.dart';

final _di = GetIt.instance;

/// Template detail page — premium "Apothecary" read-only preview.
///
/// Top-level sections are paginated into horizontal, swipeable [TabBar]
/// tabs to prevent infinite-scroll fatigue and OOM crashes on large
/// templates. Each tab renders its own isolated [ListView] of collapsed
/// sub-sections (dense Table-of-Contents mode).
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

          // Edge case: template has no sections defined yet
          if (tree.groups.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                OverviewCard(tree: tree),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'No sections defined.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          }

          // Main layout: pinned header → sticky TabBar → isolated TabBarViews
          return DefaultTabController(
            length: tree.groups.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pinned overview card — always visible above the tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: OverviewCard(tree: tree),
                ),
                const SizedBox(height: 12),

                // Scrollable horizontal tab bar: one tab per top-level section
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: tree.groups
                      .map((g) => Tab(text: g.title))
                      .toList(),
                ),

                // Each tab gets its own isolated, independently-scrollable ListView
                Expanded(
                  child: TabBarView(
                    children: tree.groups.map((group) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          // Rare: direct criteria attached to the top-level group
                          ...group.criteria.map(
                            (c) => CriterionRow(criterion: c),
                          ),
                          // Sub-sections rendered as depth-1 (non-root) SectionCards
                          ...group.children.map(
                            (sub) => SectionCard(group: sub, depth: 1),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
