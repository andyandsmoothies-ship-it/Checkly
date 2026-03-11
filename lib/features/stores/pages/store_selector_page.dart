import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../manager/store_manager.dart';
import '../model/store_dto.dart';

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

  @override
  void initState() {
    super.initState();
    _di<StoreManager>().loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StoreDto> _filtered(List<StoreDto> stores) {
    if (_searchQuery.isEmpty) return stores;
    final q = _searchQuery.toLowerCase();
    return stores.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.address?.toLowerCase().contains(q) ?? false) ||
          (s.areaCode?.toLowerCase().contains(q) ?? false);
    }).toList();
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
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
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

                final stores = _filtered(manager.stores.value);
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.store,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          store.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (store.areaCode != null) store.areaCode,
                            if (store.address != null) store.address,
                          ].join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
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
