import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../stores/manager/store_manager.dart';
import '../../stores/model/store_dto.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

/// Multi-select store picker for the Create Program wizard.
///
/// Push this page, tap stores, then tap "Done" — it pops with
/// a `List<String>` of selected store IDs.
///
/// The [storeManager] param is optional to allow widget tests to
/// instantiate the page without a GetIt setup (TC-07).
///
/// Usage:
/// ```dart
/// final ids = await Navigator.push<List<String>>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ProgramStoreSelectorPage(
///       initialSelectedIds: _draft.storeIds,
///     ),
///   ),
/// );
/// ```
class ProgramStoreSelectorPage extends StatefulWidget {
  final List<String> initialSelectedIds;
  final StoreManager? storeManager;

  const ProgramStoreSelectorPage({
    super.key,
    this.initialSelectedIds = const [],
    this.storeManager,
  });

  @override
  State<ProgramStoreSelectorPage> createState() =>
      _ProgramStoreSelectorPageState();
}

class _ProgramStoreSelectorPageState extends State<ProgramStoreSelectorPage> {
  late final StoreManager? _storeManager;

  bool _loading = false;
  String? _error;
  List<StoreDto> _stores = [];
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedIds);
    // Use injected manager if provided (test), otherwise resolve from DI (prod).
    final di = GetIt.instance;
    _storeManager =
        widget.storeManager ??
        (di.isRegistered<StoreManager>() ? di<StoreManager>() : null);
    if (_storeManager != null) {
      _loadStores();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    final manager = _storeManager;
    if (manager == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await manager.loadStores();
      setState(() {
        _stores = List<StoreDto>.from(manager.stores.value);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load stores. Please try again.';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final manager = _storeManager;
    if (manager == null) return;

    manager.searchStores(query);
    setState(() {
      _stores = List<StoreDto>.from(manager.stores.value);
    });
  }

  void _toggleStore(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _done() {
    Navigator.of(context).pop(List<String>.from(_selectedIds));
  }

  @override
  Widget build(BuildContext context) {
    final count = _selectedIds.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(count > 0 ? '$count selected' : 'Select Stores'),
        actions: [
          TextButton(
            key: const Key('store_selector_done_button'),
            onPressed: _done,
            child: Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadStores, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_stores.isEmpty) {
      return const Center(child: Text('No stores found.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: const Icon(Icons.search),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.swan, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.featherGreen,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _stores.length,
            itemBuilder: (context, i) {
              final store = _stores[i];
              final isSelected = _selectedIds.contains(store.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StrokeCard(
                  color: isSelected ? AppColors.walkingFish : null,
                  padding: EdgeInsets.zero,
                  child: CheckboxListTile(
                    key: Key('store_item_${store.id}'),
                    title: Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: store.address != null
                        ? Text(store.address!)
                        : null,
                    value: isSelected,
                    activeColor: AppColors.featherGreen,
                    onChanged: (_) => _toggleStore(store.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
