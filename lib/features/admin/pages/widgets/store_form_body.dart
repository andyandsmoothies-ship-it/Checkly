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
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Store' : 'Create Store',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name
            _PremiumField(
              label: 'Store Name *',
              child: TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Store Name *',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onMarkDirty(),
                enabled: !isSaving,
              ),
            ),
            const SizedBox(height: 20),

            // Legacy free-text address (kept for backward compatibility — SL-1 additive)
            _PremiumField(
              label: 'Address',
              child: TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  hintText: 'Address',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onMarkDirty(),
                enabled: !isSaving,
              ),
            ),
            const SizedBox(height: 20),

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
                : _PremiumField(
                    label: 'Province',
                    child: DropdownButtonFormField<String>(
                      initialValue: provinces.contains(selectedProvince)
                          ? selectedProvince
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      decoration: const InputDecoration(
                        hintText: 'Province',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
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
                  ),
            const SizedBox(height: 20),

            // SL-1: District (free text)
            _PremiumField(
              label: 'District',
              child: TextField(
                controller: districtCtrl,
                decoration: const InputDecoration(
                  hintText: 'District',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onMarkDirty(),
                enabled: !isSaving,
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 20),

            // SL-1: Ward (free text)
            _PremiumField(
              label: 'Ward',
              child: TextField(
                controller: wardCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ward',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onMarkDirty(),
                enabled: !isSaving,
                maxLength: 100,
              ),
            ),
            const SizedBox(height: 20),

            // SL-1: Street (free text)
            _PremiumField(
              label: 'Street',
              child: TextField(
                controller: streetCtrl,
                decoration: const InputDecoration(
                  hintText: 'Street',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onMarkDirty(),
                enabled: !isSaving,
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 20),

            // GPS fields (side by side)
            Row(
              children: [
                Expanded(
                  child: _PremiumField(
                    label: 'Latitude',
                    child: TextField(
                      controller: latCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Latitude',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !isSaving,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PremiumField(
                    label: 'Longitude',
                    child: TextField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Longitude',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: !isSaving,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Interactive map (extracted widget)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: StoreLocationMapWidget(
                markerPos: markerPos,
                mapController: mapController,
                isSaving: isSaving,
                onTap: onMapTap,
              ),
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

class _PremiumField extends StatelessWidget {
  final String label;
  final Widget child;

  const _PremiumField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        child,
      ],
    );
  }
}
