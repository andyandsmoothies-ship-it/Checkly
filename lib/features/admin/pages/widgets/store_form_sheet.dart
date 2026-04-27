import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../../stores/model/store_dto.dart';
import '../../../stores/services/store_api_service.dart';

void showStoreFormSheet({
  required BuildContext context,
  StoreDto? store,
  required List<Map<String, dynamic>> areas,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: false,
    builder: (ctx) =>
        StoreFormSheet(store: store, areas: areas, onSaved: onSaved),
  );
}

class StoreFormSheet extends StatefulWidget {
  final StoreDto? store;
  final List<Map<String, dynamic>> areas;
  final VoidCallback onSaved;

  const StoreFormSheet({
    super.key,
    this.store,
    required this.areas,
    required this.onSaved,
  });

  @override
  State<StoreFormSheet> createState() => _StoreFormSheetState();
}

class _StoreFormSheetState extends State<StoreFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final MapController _mapCtrl;

  String? _selectedAreaId;
  LatLng? _markerPos;
  bool _isDirty = false;
  bool _isSaving = false;

  final _di = GetIt.instance;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.store?.name ?? '');
    _addressCtrl = TextEditingController(text: widget.store?.address ?? '');
    _latCtrl = TextEditingController(
      text: widget.store?.gpsLat?.toString() ?? '',
    );
    _lngCtrl = TextEditingController(
      text: widget.store?.gpsLng?.toString() ?? '',
    );
    _selectedAreaId = widget.store?.areaId;
    _mapCtrl = MapController();

    final initLat = double.tryParse(_latCtrl.text);
    final initLng = double.tryParse(_lngCtrl.text);
    if (initLat != null && initLng != null) {
      _markerPos = LatLng(initLat, initLng);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _saveStore() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Store name is required'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.store?.id != null) {
        await _di<StoreApiService>().updateStore(
          widget.store!.id,
          name: name,
          address: _addressCtrl.text.trim().isNotEmpty
              ? _addressCtrl.text.trim()
              : null,
          areaId: _selectedAreaId,
          gpsLat: double.tryParse(_latCtrl.text.trim()),
          gpsLng: double.tryParse(_lngCtrl.text.trim()),
        );
      } else {
        await _di<StoreApiService>().createStore(
          name: name,
          address: _addressCtrl.text.trim().isNotEmpty
              ? _addressCtrl.text.trim()
              : null,
          areaId: _selectedAreaId,
          gpsLat: double.tryParse(_latCtrl.text.trim()),
          gpsLng: double.tryParse(_lngCtrl.text.trim()),
        );
      }

      if (mounted) {
        _isDirty = false;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.store?.id != null ? 'Store updated' : 'Store created',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An unexpected issue occurred. Please check your connection or restart the app.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.store != null;

    return UnsavedChangesGuard(
      isDirty: _isDirty,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store Name *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _markDirty(),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 12),

                // Address
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _markDirty(),
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 12),

                // Area dropdown
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.areas.any((a) => a['id'] == _selectedAreaId)
                      ? _selectedAreaId
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
                    ...widget.areas.map(
                      (a) => DropdownMenuItem(
                        value: a['id'] as String,
                        child: Text(a['name'] as String),
                      ),
                    ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          setState(() => _selectedAreaId = v);
                          _markDirty();
                        },
                ),
                const SizedBox(height: 12),

                // GPS fields (side by side)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        enabled: !_isSaving,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        enabled: !_isSaving,
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
                    child: IgnorePointer(
                      ignoring: _isSaving,
                      child: FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter:
                              _markerPos ?? const LatLng(15.0, 108.0),
                          initialZoom: _markerPos != null ? 14.0 : 5.5,
                          onTap: (tapPos, latlng) {
                            setState(() {
                              _markerPos = latlng;
                              _latCtrl.text = latlng.latitude.toStringAsFixed(
                                6,
                              );
                              _lngCtrl.text = latlng.longitude.toStringAsFixed(
                                6,
                              );
                            });
                            _markDirty();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.checkly.app',
                          ),
                          if (_markerPos != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _markerPos!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap on the map to set store location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveStore,
                    icon: _isSaving
                        ? Container(
                            width: 16,
                            height: 16,
                            padding: const EdgeInsets.all(2),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (isEdit ? 'Save Changes' : 'Create Store'),
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
  }
}
