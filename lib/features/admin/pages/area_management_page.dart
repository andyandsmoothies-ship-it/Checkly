import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../manager/admin_area_manager.dart';
import '../widgets/area_card.dart';
import '../widgets/area_sheets.dart';

final _di = GetIt.instance;

/// Admin: Area Management — list, search, create, edit.
class AreaManagementPage extends StatefulWidget {
  const AreaManagementPage({super.key});

  @override
  State<AreaManagementPage> createState() => _AreaManagementPageState();
}

class _AreaManagementPageState extends State<AreaManagementPage> {
  late final AdminAreaManager _manager;
  List<Map<String, dynamic>> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminAreaManager>();
    _manager.addListener(_onManagerChanged);
    _manager.load();
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) setState(() => _applyFilter());
  }

  Future<void> _loadData() => _manager.load();

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filtered = _manager.areas;
    } else {
      _filtered = _manager.areas.where((a) {
        final name = (a['name'] as String? ?? '').toLowerCase();
        final desc = (a['description'] as String? ?? '').toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  void _onSearch(String _) {
    setState(() => _applyFilter());
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AreaCreateSheet(onSuccess: _loadData),
    );
  }

  void _showEditSheet(Map<String, dynamic> area) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AreaEditSheet(area: area, onSuccess: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = _di<PolicyManager>().can(AppCapabilities.areasWrite);

    return Scaffold(
      appBar: AppBar(title: const Text('Area Management')),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: _showCreateSheet,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Content
          Expanded(child: _buildBody(theme, canWrite)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool canWrite) {
    if (_manager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_manager.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load the latest data. Please check your internet connection and refresh.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
            ),
            const SizedBox(height: 12),
            Text(
              _manager.areas.isEmpty ? 'No areas yet' : 'No matching areas',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (_manager.areas.isEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _showCreateSheet,
                child: const Text('Create First Area'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtered.length,
        itemBuilder: (_, index) {
          final area = _filtered[index];
          return AreaCard(
            area: area,
            onTap: canWrite ? () => _showEditSheet(area) : null,
          );
        },
      ),
    );
  }
}
