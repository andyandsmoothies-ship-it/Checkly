import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/utils/date_format_utils.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../manager/template_manager.dart';
import '../models/template_dto.dart';

final _di = GetIt.instance;

/// Returns a human-readable relative time string.
/// Delegates to shared [timeAgo] utility.
String _timeAgo(DateTime dt) => timeAgo(dt);

/// Template type labels matching PWA TemplateCard constants.
const kTemplateTypeLabels = <String, String>{
  'qc': 'QUALITY CONTROL',
  'training': 'TRAINING',
  'general': 'GENERAL',
  'task force': 'TASK FORCE',
  'task_force': 'TASK FORCE',
};

/// Display order for template types.
const _typeOrder = ['qc', 'training', 'general', 'task force'];

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<TemplateManager>().loadTemplates();
    });
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

  /// Groups filtered templates by type, respecting _typeOrder.
  /// Always includes all types from _typeOrder even if empty (Fix 4).
  Map<String, List<TemplateDto>> get _groupedByType {
    final items = _filtered;
    // Seed with all known types so empty sections appear
    final groups = <String, List<TemplateDto>>{
      for (final type in _typeOrder) type: [],
    };
    for (final t in items) {
      groups.putIfAbsent(t.type, () => []).add(t);
    }
    // Sort keys by _typeOrder, unknowns at end
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final ia = _typeOrder.indexOf(a);
        final ib = _typeOrder.indexOf(b);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });
    return {for (final k in sortedKeys) k: groups[k]!};
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => context.push('/templates/new'),
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
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
                    WarmChip(
                      label: 'All',
                      count: _countByFilter('all'),
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Published',
                      count: _countByFilter('published'),
                      selected: _filter == 'published',
                      onTap: () => setState(() => _filter = 'published'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Draft',
                      count: _countByFilter('draft'),
                      selected: _filter == 'draft',
                      onTap: () => setState(() => _filter = 'draft'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Grouped template list — always shows all type sections (Fix 4)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => manager.loadTemplates(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: _groupedByType.entries.map((entry) {
                      final type = entry.key;
                      final templates = entry.value;
                      final label =
                          kTemplateTypeLabels[type] ?? type.toUpperCase();
                      return _TypeSection(
                        label: label,
                        count: templates.length,
                        initiallyExpanded: false,
                        children: templates
                            .map((t) => _TemplateCard(template: t))
                            .toList(),
                      );
                    }).toList(),
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

// ── Type Section (collapsible group) ──

class _TypeSection extends StatelessWidget {
  final String label;
  final int count;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _TypeSection({
    required this.label,
    required this.count,
    this.initiallyExpanded = true,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              label,
              style: AppFonts.displayStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal.withValues(alpha: 0.4),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: children,
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
                    // Updated time (Fix 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Updated ${_timeAgo(template.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Context menu
              PopupMenuButton<String>(
                tooltip: '',
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'start':
                      context.push('/stores/select?templateId=${template.id}');
                    case 'edit':
                      context.push('/templates/edit/${template.id}');
                    case 'duplicate':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Duplicate — coming soon'),
                        ),
                      );
                    case 'delete':
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Template'),
                          content: Text(
                            'Delete "${template.title}"? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await _di<TemplateManager>().deleteTemplate(
                                    template.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Template deleted'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'start',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Quick Start'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      dense: true,
                    ),
                  ),
                ],
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
