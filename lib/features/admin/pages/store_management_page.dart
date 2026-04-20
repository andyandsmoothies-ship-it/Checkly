import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';
import '../manager/admin_store_manager.dart';

final _di = GetIt.instance;

/// Admin: Store Management — list, create, edit, deactivate, transfer SM.
class StoreManagementPage extends StatefulWidget {
  final String? initialAreaId;
  const StoreManagementPage({super.key, this.initialAreaId});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  late final AdminStoreManager _manager;
  String? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    _manager = _di<AdminStoreManager>();
    _selectedAreaId = widget.initialAreaId;
    _manager.load(areaId: _selectedAreaId);
  }

  Future<void> _loadData() => _manager.load(areaId: _selectedAreaId);

  // ─── Create / Edit ───

  void _showStoreForm({StoreDto? store}) {
    final isEdit = store != null;
    final nameCtrl = TextEditingController(text: store?.name ?? '');
    final addressCtrl = TextEditingController(text: store?.address ?? '');
    final latCtrl = TextEditingController(
      text: store?.gpsLat?.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: store?.gpsLng?.toString() ?? '',
    );
    String? selectedAreaId = store?.areaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      builder: (ctx) {
        // Map state
        LatLng? markerPos;
        final initLat = double.tryParse(latCtrl.text);
        final initLng = double.tryParse(lngCtrl.text);
        if (initLat != null && initLng != null) {
          markerPos = LatLng(initLat, initLng);
        }
        final mapCtrl = MapController();

        var isDirty = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void markDirty() {
              if (!isDirty) setSheetState(() => isDirty = true);
            }

            return UnsavedChangesGuard(
              isDirty: isDirty,
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Store' : 'Create Store',
                              style: Theme.of(ctx).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.maybePop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Name
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Store Name *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => markDirty(),
                        ),
                        const SizedBox(height: 12),

                        // Address
                        TextField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => markDirty(),
                        ),
                        const SizedBox(height: 12),

                        // Area dropdown
                        DropdownButtonFormField<String>(
                          initialValue:
                              _manager.areas.any((a) => a['id'] == selectedAreaId)
                              ? selectedAreaId
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          decoration: const InputDecoration(
                            labelText: 'Area',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('— None —'),
                            ),
                            ..._manager.areas.map(
                              (a) => DropdownMenuItem(
                                value: a['id'] as String,
                                child: Text(a['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setSheetState(() => selectedAreaId = v);
                            markDirty();
                          },
                        ),
                        const SizedBox(height: 12),

                        // GPS fields (side by side)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: lngCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Interactive map
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 220,
                            child: FlutterMap(
                              mapController: mapCtrl,
                              options: MapOptions(
                                initialCenter:
                                    markerPos ?? const LatLng(15.0, 108.0),
                                initialZoom: markerPos != null ? 14.0 : 5.5,
                                onTap: (tapPos, latlng) {
                                  setSheetState(() {
                                    markerPos = latlng;
                                    latCtrl.text = latlng.latitude
                                        .toStringAsFixed(6);
                                    lngCtrl.text = latlng.longitude
                                        .toStringAsFixed(6);
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.checkly.app',
                                ),
                                if (markerPos != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: markerPos!,
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.location_on,
                                          color: Theme.of(ctx).colorScheme.primary,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap on the map to set store location',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _saveStore(
                              existingId: store?.id,
                              name: nameCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              areaId: selectedAreaId,
                              gpsLat: double.tryParse(latCtrl.text.trim()),
                              gpsLng: double.tryParse(lngCtrl.text.trim()),
                            ),
                            icon: const Icon(Icons.save),
                            label: Text(
                              isEdit ? 'Save Changes' : 'Create Store',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveStore({
    String? existingId,
    required String name,
    String? address,
    String? areaId,
    double? gpsLat,
    double? gpsLng,
  }) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Store name is required'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.of(context).pop(); // Close sheet

    try {
      if (existingId != null) {
        await _di<StoreApiService>().updateStore(
          existingId,
          name: name,
          address: address?.isNotEmpty == true ? address : null,
          areaId: areaId,
          gpsLat: gpsLat,
          gpsLng: gpsLng,
        );
      } else {
        await _di<StoreApiService>().createStore(
          name: name,
          address: address?.isNotEmpty == true ? address : null,
          areaId: areaId,
          gpsLat: gpsLat,
          gpsLng: gpsLng,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingId != null ? 'Store updated' : 'Store created',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected issue occurred. Please check your connection or restart the app.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

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
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected issue occurred. Please check your connection or restart the app.'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  // ─── Transfer SM ───

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStoreForm(),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          return Column(
            children: [
              // Area filter dropdown
              if (_manager.areas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedAreaId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Area',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Areas')),
                    ..._manager.areas.map(
                      (a) => DropdownMenuItem(
                        value: a['id'] as String,
                        child: Text(a['name'] as String),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedAreaId = v);
                    _loadData();
                  },
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
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
            Text('We couldn\'t load the latest data. Please check your internet connection and refresh.', style: theme.textTheme.titleMedium),
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
        icon: Icons.storefront_outlined,
        title: 'No stores yet',
        subtitle: 'Tap + to create your first store.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _manager.stores.length,
        itemBuilder: (context, index) {
          final store = _manager.stores[index];
          return _StoreCard(
            store: store,
            onEdit: () => _showStoreForm(store: store),
            onToggleActive: () => _toggleActive(store),
          );
        },
      ),
    );
  }
}

// ─── Store Card ───

class _StoreCard extends StatelessWidget {
  final StoreDto store;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _StoreCard({
    required this.store,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = store.isActive ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + status
              Row(
                children: [
                  // Store icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: isActive ? theme.colorScheme.primary : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isActive ? null : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (store.areaName != null)
                          Text(
                            store.areaName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive ? AppTheme.success : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 3-dot menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'toggle') onToggleActive();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Store'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ],
                  ),
                ],
              ),

              // Address (if present)
              if (store.address != null && store.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        store.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Manager row (always visible)
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    store.managerName != null
                        ? Icons.person_outline
                        : Icons.warning_amber,
                    size: 14,
                    color: store.managerName != null
                        ? theme.colorScheme.onSurfaceVariant
                        : AppTheme.warning,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      store.managerName != null
                          ? 'SM: ${store.managerName!}'
                          : 'SM: Unassigned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: store.managerName != null
                            ? theme.colorScheme.onSurfaceVariant
                            : AppTheme.warning,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
