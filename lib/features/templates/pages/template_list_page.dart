import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/widgets/permission_guard.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/bubbly_button.dart';
import '../manager/template_manager.dart';
import '../models/template_dto.dart';
import '../widgets/template_card.dart';
import '../widgets/type_section.dart';

part 'template_list_page_logic.dart';

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
  final _searchController = TextEditingController();
  String _search = '';
  String _filter = 'all'; // all, published, draft

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<TemplateManager>().loadTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = _di<TemplateManager>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
      ),
      floatingActionButton: PermissionGuard(
        capability: AppCapabilities.templatesCreate,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Builder(
            builder: (context) {
              return FloatingActionButton(
                onPressed: () => _showCreateMenu(context),
                shape: const CircleBorder(),
                backgroundColor: AppColors.featherGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                child: const Icon(Icons.add, size: 28),
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
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.cardinal,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    manager.error!,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: AppColors.eel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 140,
                    height: 44,
                    child: BubblyButton(
                      label: 'Retry',
                      color: AppColors.cardinal,
                      height: 40,
                      onPressed: () => manager.loadTemplates(),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: AppColors.eel,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppColors.wolf,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.wolf),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.wolf),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.swan, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.featherGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // Filter status pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    DropdownFilterPill(
                      label: 'Status',
                      value: switch (_filter) {
                        'all' => 'All',
                        'published' => 'Published',
                        'draft' => 'Draft',
                        _ => _filter,
                      },
                      active: _filter != 'all',
                      onTap: () => showTemplateStatusFilterSheet(
                        context: context,
                        currentFilter: _filter,
                        countByFilter: _countByFilter,
                        onSelected: (val) => setState(() => _filter = val),
                      ),
                    ),
                  ],
                ),
              ),

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
                            .map((t) => TemplateCard(template: t))
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

class DropdownFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const DropdownFilterPill({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(
                color: active ? Colors.white : AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.eel,
            ),
          ],
        ),
      ),
    );
  }
}

void showTemplateStatusFilterSheet({
  required BuildContext context,
  required String currentFilter,
  required int Function(String) countByFilter,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final statuses = [
        {'id': 'all', 'label': 'All Templates', 'count': countByFilter('all')},
        {'id': 'published', 'label': 'Published', 'count': countByFilter('published')},
        {'id': 'draft', 'label': 'Draft', 'count': countByFilter('draft')},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...statuses.map((status) {
                final isSelected = currentFilter == status['id'];
                return InkWell(
                  onTap: () {
                    onSelected(status['id'] as String);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.featherGreen.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              status['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.featherGreen : AppColors.eel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.featherGreen
                                    : AppColors.swan.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${status['count']}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.eel.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
