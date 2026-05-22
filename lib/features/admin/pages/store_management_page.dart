import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';
import '../manager/admin_store_manager.dart';
import 'widgets/store_card.dart';
import 'widgets/store_form_sheet.dart';

final _di = GetIt.instance;

/// Admin: Store Management — list, create, edit, deactivate, transfer SM.
class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  late final AdminStoreManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminStoreManager>();
    _manager.load();
  }

  Future<void> _loadData() => _manager.load();

  // ─── Deactivate / Activate ───

  Future<void> _toggleActive(StoreDto store) async {
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
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final canWrite = _di<PolicyManager>().can(AppCapabilities.storesWrite);
    return Scaffold(
      appBar: AppBar(title: const Text('Store Management')),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              onPressed: () =>
                  showStoreFormSheet(context: context, onSaved: _loadData),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          return _buildBody(canWrite);
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
    if (_manager.stores.isEmpty) {
      return const ChecklyEmptyState(
        emoji: '🏪',
        title: 'Ready for your first store?',
        subtitle:
            'Tap the circular + button to create a new location and start auditing!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _manager.stores.length,
        itemBuilder: (context, index) {
          final store = _manager.stores[index];
          return StoreCard(
            store: store,
            onEdit: canWrite
                ? () => showStoreFormSheet(
                    context: context,
                    store: store,
                    onSaved: _loadData,
                  )
                : null,
            onToggleActive: canWrite ? () => _toggleActive(store) : null,
          );
        },
      ),
    );
  }
}
