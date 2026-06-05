import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
import 'package:checkly/_shared/widgets/checkly_empty_state.dart';
import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';
import '../manager/admin_store_manager.dart';
import 'widgets/dropdown_filter_pill.dart';
import 'widgets/store_card.dart';
import 'widgets/store_form_sheet.dart';
import 'widgets/store_status_filter_sheet.dart';
import 'widgets/store_province_filter_sheet.dart';
import 'widgets/store_manager_filter_sheet.dart';

final _di = GetIt.instance;

/// Admin: Store Management — list, search, status filter, create, edit, deactivate, transfer SM.
class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  final _searchController = TextEditingController();
  late final AdminStoreManager _manager;
  String _selectedStatus = 'all';
  String? _togglingStoreId;

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminStoreManager>();
    _manager.load(search: _searchController.text.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() =>
      _manager.load(search: _searchController.text.trim());

  Future<void> _onSearch(String _) => _loadData();

  // ─── Deactivate / Activate ───

  Future<void> _toggleActive(StoreDto store) async {
    if (_togglingStoreId != null) return;

    final newActive = !(store.isActive ?? true);

    // Deactivation is destructive — confirm first
    if (!newActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate Store?'),
          content: Text(
            'Are you sure you want to deactivate "${store.name}"? '
            'Auditors will no longer be able to submit audits to this store.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _togglingStoreId = store.id);

    try {
      await _di<StoreApiService>().updateStore(store.id, isActive: newActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Store activated' : 'Store deactivated'),
            backgroundColor: newActive ? AppTheme.success : AppTheme.warning,
          ),
        );
        _loadData();
      }
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (_) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    } finally {
      if (mounted) {
        setState(() => _togglingStoreId = null);
      }
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final canWrite = _di<PolicyManager>().can(AppCapabilities.storesWrite);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              key: const Key('create_store_fab'),
              tooltip: 'Add Store',
              backgroundColor: AppColors.featherGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              onPressed: () =>
                  showStoreFormSheet(context: context, onSaved: _loadData),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
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
                    hintText: 'Search by store name or address...',
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
                              _onSearch('');
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
                  onSubmitted: _onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Filters row (scrollable horizontally to prevent overflow)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownFilterPill(
                        label: 'Status',
                        value: switch (_selectedStatus) {
                          'all' => 'All',
                          'active' => 'Active',
                          'inactive' => 'Inactive',
                          _ => _selectedStatus,
                        },
                        active: _selectedStatus != 'all',
                        onTap: () => showStoreStatusFilterSheet(
                          context: context,
                          currentFilter: _selectedStatus,
                          countByStatus: (status) {
                            if (status == 'all') return _manager.stores.length;
                            final activeVal = status == 'active';
                            return _manager.stores.where((s) => (s.isActive ?? true) == activeVal).length;
                          },
                          onSelected: (val) => setState(() => _selectedStatus = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownFilterPill(
                        key: const Key('province_filter_pill'),
                        label: 'Province',
                        value: _manager.selectedProvince ?? 'All',
                        active: _manager.selectedProvince != null,
                        onTap: () => showStoreProvinceFilterSheet(
                          context: context,
                          currentProvince: _manager.selectedProvince,
                          onSelected: (val) => _manager.setProvince(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownFilterPill(
                        key: const Key('manager_filter_pill'),
                        label: 'Manager',
                        value: _manager.selectedManagerName ?? 'All',
                        active: _manager.selectedManagerName != null,
                        onTap: () => showStoreManagerFilterSheet(
                          context: context,
                          currentManagerName: _manager.selectedManagerName,
                          onSelected: (val) => _manager.setManagerName(val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _buildBody(canWrite),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(bool canWrite) {
    final theme = Theme.of(context);

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
              textAlign: TextAlign.center,
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

    final filtered = _manager.stores.where((store) {
      if (_selectedStatus == 'all') return true;
      final activeVal = _selectedStatus == 'active';
      return (store.isActive ?? true) == activeVal;
    }).toList();

    if (filtered.isEmpty) {
      final isFilteredOrSearched = _searchController.text.trim().isNotEmpty ||
          _selectedStatus != 'all' ||
          _manager.selectedProvince != null ||
          _manager.selectedManagerName != null;
      if (isFilteredOrSearched) {
        return const ChecklyEmptyState(
          emoji: '🏪',
          title: "Let's find some stores!",
          subtitle:
              'Try adjusting your search or status filter to find locations.',
        );
      } else {
        return const ChecklyEmptyState(
          emoji: '🏪',
          title: 'Ready for your first store?',
          subtitle:
              'Tap the circular + button to create a new location and start auditing!',
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final store = filtered[index];
          final isTogglingThis = _togglingStoreId == store.id;
          return StoreCard(
            store: store,
            isToggling: isTogglingThis,
            onEdit: canWrite && _togglingStoreId == null
                ? () => showStoreFormSheet(
                    context: context,
                    store: store,
                    onSaved: _loadData,
                  )
                : null,
            onToggleActive: canWrite && _togglingStoreId == null ? () => _toggleActive(store) : null,
          );
        },
      ),
    );
  }
}
