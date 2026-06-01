import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';
import '../manager/store_manager.dart';
import '../model/store_dto.dart';
import '../../../_shared/theme/app_colors.dart';

final _di = GetIt.instance;

/// Store selector page — searchable list to pick a store for audit.
class StoreSelectorPage extends StatefulWidget {
  final String templateId;

  const StoreSelectorPage({super.key, required this.templateId});

  @override
  State<StoreSelectorPage> createState() => _StoreSelectorPageState();
}

class _StoreSelectorPageState extends State<StoreSelectorPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _di<StoreManager>().loadStores();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _di<StoreManager>().searchStores(value);
    });
  }

  void _showStoreInfo(BuildContext context, StoreDto store) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      store.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.wolf),
                    onPressed: () => Navigator.maybePop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      store.address ?? 'Address not available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    store.managerName ?? 'Not available offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      '/audit?templateId=${widget.templateId}&storeId=${store.id}',
                    );
                  },
                  child: const Text('Start Audit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<StoreManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Store')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // List
          Expanded(
            child: ListenableBuilder(
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
                        Text(manager.error!),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => manager.loadStores(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final stores = manager.stores.value;
                if (stores.isEmpty) {
                  return Center(
                    child: Text(
                      'No stores found',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.sageGray.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.store_outlined,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          store.name,
                          style: AppFonts.displayStyle(
                            fontSize: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.fontSize,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          store.address ?? '',
                          style: AppFonts.displayStyle(
                            fontSize: Theme.of(
                              context,
                            ).textTheme.bodySmall?.fontSize,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: AppTheme.sageGray,
                          iconSize: 20,
                          onPressed: () => _showStoreInfo(context, store),
                        ),
                        onTap: () {
                          context.push(
                            '/audit?templateId=${widget.templateId}&storeId=${store.id}',
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
