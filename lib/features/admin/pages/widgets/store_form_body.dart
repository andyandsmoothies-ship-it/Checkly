import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../stores/widgets/store_location_map_widget.dart';

/// The entire scrollable form content for [StoreFormSheet].
///
/// Stateless — all mutable state lives in the parent [_StoreFormSheetState].
class StoreFormBody extends StatelessWidget {
  final bool isEdit;
  final bool isSaving;
  final bool provincesLoading;

  // Controllers
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController wardCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;

  // Province dropdown state
  final List<String> provinces;
  final String? selectedProvince;

  // Map state
  final LatLng? markerPos;
  final MapController mapController;

  // Callbacks
  final VoidCallback onMarkDirty;
  final ValueChanged<String?> onProvinceChanged;
  final void Function(TapPosition tapPos, LatLng latlng) onMapTap;
  final VoidCallback onSave;

  const StoreFormBody({
    super.key,
    required this.isEdit,
    required this.isSaving,
    required this.provincesLoading,
    required this.nameCtrl,
    required this.addressCtrl,
    required this.districtCtrl,
    required this.wardCtrl,
    required this.streetCtrl,
    required this.latCtrl,
    required this.lngCtrl,
    required this.provinces,
    required this.selectedProvince,
    required this.markerPos,
    required this.mapController,
    required this.onMarkDirty,
    required this.onProvinceChanged,
    required this.onMapTap,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Store Name *',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onMarkDirty(),
              enabled: !isSaving,
            ),
            const SizedBox(height: 12),

            // Legacy free-text address (kept for backward compatibility — SL-1 additive)
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onMarkDirty(),
              enabled: !isSaving,
            ),
            const SizedBox(height: 12),

            // SL-1: Province dropdown (replaces Area dropdown)
            provincesLoading
                ? const SizedBox(
                    height: 56,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: provinces.contains(selectedProvince)
                        ? selectedProvince
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    decoration: const InputDecoration(
                      labelText: 'Province',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Select Province —'),
                      ),
                      ...provinces.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p)),
                      ),
                    ],
                    onChanged: isSaving ? null : onProvinceChanged,
                  ),
            const SizedBox(height: 12),

            // SL-1: District (free text)
            TextField(
              controller: districtCtrl,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onMarkDirty(),
              enabled: !isSaving,
              maxLength: 100,
            ),
            const SizedBox(height: 4),

            // SL-1: Ward (free text)
            TextField(
              controller: wardCtrl,
              decoration: const InputDecoration(
                labelText: 'Ward',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onMarkDirty(),
              enabled: !isSaving,
              maxLength: 100,
            ),
            const SizedBox(height: 4),

            // SL-1: Street (free text)
            TextField(
              controller: streetCtrl,
              decoration: const InputDecoration(
                labelText: 'Street',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onMarkDirty(),
              enabled: !isSaving,
              maxLength: 200,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    enabled: !isSaving,
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    enabled: !isSaving,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Interactive map (extracted widget)
            StoreLocationMapWidget(
              markerPos: markerPos,
              mapController: mapController,
              isSaving: isSaving,
              onTap: onMapTap,
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
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
                  isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Save Changes' : 'Create Store'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
