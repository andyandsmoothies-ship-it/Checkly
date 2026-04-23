import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../services/admin_api_service.dart';
import '../manager/admin_global_risk_manager.dart';

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

class _GlobalRiskManagementPageState
    extends State<GlobalRiskManagementPage> {
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

  void _showCreateSheet() {
    final labelCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var isDirty = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void markDirty() {
              if (!isDirty) setSheetState(() => isDirty = true);
            }

            return UnsavedChangesGuard(
              isDirty: isDirty,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Global Risk',
                          style: AppFonts.displayStyle(
                            fontSize:
                                Theme.of(ctx).textTheme.titleLarge?.fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.maybePop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Risk Label *',
                        hintText: 'e.g. Critical Food Safety Violation',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => markDirty(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'When should an auditor trigger this risk?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => markDirty(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final label = labelCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        if (label.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Risk label is required'),
                            ),
                          );
                          return;
                        }
                        try {
                          await _di<AdminApiService>().createGlobalRisk(
                            label: label,
                            description: desc.isNotEmpty ? desc : null,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Global risk created'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                            _loadData();
                          }
                        } on DioException catch (e) {
                          if (mounted) {
                            final msg =
                                e.response?.data?['message'] ??
                                'Failed to create global risk';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg.toString()),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Create Risk'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet(Map<String, dynamic> risk) {
    final labelCtrl =
        TextEditingController(text: risk['label'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: risk['description'] as String? ?? '');
    final isActive = risk['isActive'] as bool? ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var isDirty = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void markDirty() {
              if (!isDirty) setSheetState(() => isDirty = true);
            }

            return UnsavedChangesGuard(
              isDirty: isDirty,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Global Risk',
                          style: AppFonts.displayStyle(
                            fontSize:
                                Theme.of(ctx).textTheme.titleLarge?.fontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.maybePop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Risk Label *',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => markDirty(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => markDirty(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final label = labelCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        if (label.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Label is required')),
                          );
                          return;
                        }
                        try {
                          await _di<AdminApiService>().updateGlobalRisk(
                            risk['id'] as String,
                            label: label,
                            description: desc,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Global risk updated'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                            _loadData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'An unexpected issue occurred. Please check your connection.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(ctx).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Deactivate Risk?'),
                              content: const Text(
                                'This risk will no longer appear during new audits. '
                                'Historical audit data referencing this risk will not be affected.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(true),
                                  child: Text(
                                    'Deactivate',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              await _di<AdminApiService>().deleteGlobalRisk(
                                risk['id'] as String,
                              );
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Risk deactivated'),
                                  ),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'An unexpected issue occurred. Please check your connection.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Deactivate Risk'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Global Risk Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
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
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
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
                onPressed: _showCreateSheet,
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
          return _RiskCard(risk: risk, onTap: () => _showEditSheet(risk));
        },
      ),
    );
  }
}

// ─── Risk Card ───

class _RiskCard extends StatelessWidget {
  final Map<String, dynamic> risk;
  final VoidCallback onTap;

  const _RiskCard({required this.risk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = risk['label'] as String? ?? 'Unnamed';
    final description = risk['description'] as String? ?? '';
    final isActive = risk['isActive'] as bool? ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.warning.withAlpha(25)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: isActive
                      ? AppTheme.warning
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppFonts.displayStyle(
                              fontSize:
                                  theme.textTheme.titleSmall?.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
