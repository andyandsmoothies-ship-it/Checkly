import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/checkly_fab.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/template_manager.dart';
import '../model/template_dto.dart';

final _di = GetIt.instance;

/// Template list page — search, filter tabs, and FAB.
/// Matches PWA spec: search bar, Published/Draft tabs, template cards.
class TemplateListPage extends StatefulWidget {
  const TemplateListPage({super.key});

  @override
  State<TemplateListPage> createState() => _TemplateListPageState();
}

class _TemplateListPageState extends State<TemplateListPage> {
  String _search = '';
  String _filter = 'all'; // all, published, draft

  @override
  void initState() {
    super.initState();
    _di<TemplateManager>().loadTemplates();
  }

  List<TemplateDto> get _filtered {
    final manager = _di<TemplateManager>();
    var items = manager.templates.value;

    // Filter by status (published = isActive, draft = !isActive)
    if (_filter == 'published') {
      items = items.where((t) => t.isActive).toList();
    } else if (_filter == 'draft') {
      items = items.where((t) => !t.isActive).toList();
    }

    // Filter by search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.type.toLowerCase().contains(q),
          )
          .toList();
    }

    return items;
  }

  int _countByFilter(String filter) {
    final all = _di<TemplateManager>().templates.value;
    if (filter == 'all') return all.length;
    if (filter == 'published') return all.where((t) => t.isActive).length;
    if (filter == 'draft') return all.where((t) => !t.isActive).length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<TemplateManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: ChecklyFab(
        label: 'CREATE',
        onPressed: () => context.push('/templates/new'),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          if (manager.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (manager.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(manager.error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => manager.loadTemplates(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: _countByFilter('all'),
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Published',
                      count: _countByFilter('published'),
                      selected: _filter == 'published',
                      onTap: () => setState(() => _filter = 'published'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Draft',
                      count: _countByFilter('draft'),
                      selected: _filter == 'draft',
                      onTap: () => setState(() => _filter = 'draft'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Template list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withAlpha(80),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No templates found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => manager.loadTemplates(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _TemplateCard(template: _filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter Chip ──

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : AppTheme.oatmeal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Template Card ──

/// Card for a single template in the list.
class _TemplateCard extends StatelessWidget {
  final TemplateDto template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/templates/${template.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeBadge(type: template.type),
                        const SizedBox(width: 8),
                        Text(
                          'v${template.version}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (!template.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.softPeach,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DRAFT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.charcoal.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge showing template type (weighted, checklist, etc.)
class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
