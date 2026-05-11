import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/widgets/permission_guard.dart';
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
      bottomNavigationBar: PermissionGuard(
        capability: AppCapabilities.submissionsCreate,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                  '/stores/select?templateId=${widget.templateId}',
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('START AUDIT'),
              ),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          if (manager.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final tree = manager.selectedTemplate.value;

          // Prevent UI flicker by explicitly ensuring the loaded tree matches the route ID.
          // If they don't match, the manager hasn't updated its state yet from the previous template.
          if (tree != null && tree.id != widget.templateId) {
            return const Center(child: CircularProgressIndicator());
          }

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

          // Main layout: NestedScrollView allows header to scroll out of view while pinning tabs
          return DefaultTabController(
            key: ValueKey(tree.id),
            length: tree.groups.length,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: OverviewCard(tree: tree),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: tree.groups
                            .map((g) => Tab(text: g.title))
                            .toList(),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: tree.groups.map((group) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      // Rare: direct criteria attached to the top-level group
                      ...group.criteria.map((c) => CriterionRow(criterion: c)),
                      // Sub-sections rendered as depth-1 (non-root) SectionCards
                      ...group.children.map(
                        (sub) => SectionCard(group: sub, depth: 1),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
