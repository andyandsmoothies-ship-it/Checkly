import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../manager/admin_global_risk_manager.dart';
import 'widgets/risk_card.dart';
import 'widgets/risk_form_sheet.dart';

final _di = GetIt.instance;

/// Admin: Global Risk Management — list, create, edit, deactivate.
///
/// Global Risks are admin-defined named risk categories (e.g. "Food Safety
/// Violation") shown in the Shield Panel during an audit. Requires the
/// `global_risks:manage` PBAC capability at the API level.
class GlobalRiskManagementPage extends StatefulWidget {
  const GlobalRiskManagementPage({super.key});

  @override
  State<GlobalRiskManagementPage> createState() =>
      _GlobalRiskManagementPageState();
}

class _GlobalRiskManagementPageState extends State<GlobalRiskManagementPage> {
  late final AdminGlobalRiskManager _manager;
  List<Map<String, dynamic>> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminGlobalRiskManager>();
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
      _filtered = _manager.risks;
    } else {
      _filtered = _manager.risks.where((r) {
        final label = (r['label'] as String? ?? '').toLowerCase();
        final desc = (r['description'] as String? ?? '').toLowerCase();
        return label.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  void _onSearch(String _) {
    setState(() => _applyFilter());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = _di<PolicyManager>().can(
      AppCapabilities.globalRisksManage,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Global Risk Management')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () =>
                  showRiskFormSheet(context: context, onSaved: _loadData),
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
                hintText: 'Search by label or description...',
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
          Expanded(child: _buildBody(theme, canManage)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool canManage) {
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
            const Text(
              'We couldn\'t load global risks. Please check your connection and try again.',
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
              Icons.shield_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
            ),
            const SizedBox(height: 12),
            Text(
              _manager.risks.isEmpty
                  ? 'No global risks configured yet'
                  : 'No matching risks',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (_manager.risks.isEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    showRiskFormSheet(context: context, onSaved: _loadData),
                child: const Text('Create First Risk'),
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
          final risk = _filtered[index];
          return RiskCard(
            risk: risk,
            onTap: canManage
                ? () => showRiskFormSheet(
                    context: context,
                    risk: risk,
                    onSaved: _loadData,
                  )
                : null,
          );
        },
      ),
    );
  }
}
