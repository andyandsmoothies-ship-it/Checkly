import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../stores/services/store_api_service.dart';
import '../../stores/model/store_dto.dart';
import '../services/admin_api_service.dart';

final _di = GetIt.instance;

/// Admin: Store Management — list, create, edit, deactivate, transfer SM.
class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  List<StoreDto> _stores = [];
  List<Map<String, dynamic>> _areas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storesFuture = _di<StoreApiService>().getStores();
      final areasFuture = _loadAreas();

      final stores = await storesFuture;
      final areas = await areasFuture;

      if (!mounted) return;
      setState(() {
        _stores = stores;
        _areas = areas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadAreas() async {
    final dio = _di<Dio>();
    final response = await dio.get('/areas');
    final list = response.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

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
      builder: (ctx) {
        // Map state
        LatLng? markerPos;
        final initLat = double.tryParse(latCtrl.text);
        final initLng = double.tryParse(lngCtrl.text);
        if (initLat != null && initLng != null) {
          markerPos = LatLng(initLat, initLng);
        }
        final mapCtrl = MapController();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Store' : 'Create Store',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Store Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Address
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Area dropdown
                      DropdownButtonFormField<String>(
                        value: _areas.any((a) => a['id'] == selectedAreaId)
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
                          ..._areas
                              .where((a) => a['isActive'] == true)
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a['id'] as String,
                                  child: Text(a['name'] as String),
                                ),
                              ),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => selectedAreaId = v),
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
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
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
                          label: Text(isEdit ? 'Save Changes' : 'Create Store'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
        const SnackBar(
          content: Text('Store name is required'),
          backgroundColor: Colors.red,
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
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Deactivate / Activate ───

  Future<void> _toggleActive(StoreDto store) async {
    final newActive = !(store.isActive ?? true);
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
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Transfer SM ───

  void _showTransferDialog(StoreDto store) {
    final managerIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Store Manager'),
        content: TextField(
          controller: managerIdCtrl,
          decoration: const InputDecoration(
            labelText: 'New Manager User ID',
            border: OutlineInputBorder(),
            helperText: 'Enter the user ID of the new store manager',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = managerIdCtrl.text.trim();
              if (id.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _di<AdminApiService>().transferStoreManager(
                  store.id,
                  newManagerId: id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Store manager transferred'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }

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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Failed to load stores', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_stores.isEmpty) {
      return const Center(
        child: Text('No stores yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _stores.length,
        itemBuilder: (context, index) {
          final store = _stores[index];
          return _StoreCard(
            store: store,
            onEdit: () => _showStoreForm(store: store),
            onToggleActive: () => _toggleActive(store),
            onTransferSm: () => _showTransferDialog(store),
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
  final VoidCallback onTransferSm;

  const _StoreCard({
    required this.store,
    required this.onEdit,
    required this.onToggleActive,
    required this.onTransferSm,
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

              // Manager name (if assigned)
              if (store.managerName != null &&
                  store.managerName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'SM: ${store.managerName!}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons row
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTransferSm,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Transfer SM'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onToggleActive,
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle_outline,
                      size: 16,
                      color: isActive ? Colors.red : AppTheme.success,
                    ),
                    label: Text(
                      isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                        color: isActive ? Colors.red : AppTheme.success,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
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
