import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/widgets/permission_guard.dart';
import '../../../_shared/widgets/warm_chip.dart';
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
  Widget build(BuildContext context) {
    final manager = _di<TemplateManager>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Templates',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: PermissionGuard(
        capability: AppCapabilities.templatesCreate,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Builder(
            builder: (context) {
              return FloatingActionButton(
                onPressed: () => _showCreateMenu(context),
                shape: CircleBorder(
                  side: BorderSide(
                    color:
                        Color.lerp(
                          AppColors.featherGreen,
                          Colors.black,
                          0.25,
                        ) ??
                        AppColors.featherGreen,
                    width: 2,
                  ),
                ),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: AppColors.eel,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: AppColors.wolf,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.wolf),
                    isDense: true,
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.swan,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.macaw,
                        width: 2,
                      ),
                    ),
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
