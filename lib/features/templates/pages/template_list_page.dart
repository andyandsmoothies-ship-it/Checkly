import 'package:flutter/material.dart';
import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/widgets/permission_guard.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/warm_chip.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/template_manager.dart';
import '../models/template_dto.dart';
import '../widgets/template_card.dart';
import '../widgets/type_section.dart';

final _di = GetIt.instance;


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

  /// Shows a popup menu with 2 creation options.
  /// Uses showMenu() — never wraps FAB in PopupMenuButton (Gotcha #2).
  void _showCreateMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(
          value: 'classic',
          child: ListTile(
            leading: Icon(Icons.build_outlined),
            title: Text('Classic Builder'),
            subtitle: Text('Full control over every detail'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'wizard',
          child: ListTile(
            leading: Icon(Icons.auto_fix_high),
            title: Text('Guided Creation'),
            subtitle: Text('Step-by-step for quick setup'),
            dense: true,
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    switch (result) {
      case 'classic':
        context.push('/templates/new');
      case 'wizard':
        context.push('/templates/wizard');
    }
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
    final isAdmin = _di<AuthManager>().currentUser?.role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: PermissionGuard(
          capability: AppCapabilities.templatesCreate,
          child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return FloatingActionButton(
                    onPressed: () => _showCreateMenu(context),
                    shape: const CircleBorder(),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 4,
                    child: const Icon(Icons.add),
                  );
                },
              ),
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
                      return TypeSection(
                        label: label,
                        count: templates.length,
                        initiallyExpanded: false,
                        children: templates
                            .map((t) => TemplateCard(template: t, isAdmin: isAdmin))
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
