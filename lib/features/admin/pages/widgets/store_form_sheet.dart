import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../../stores/model/store_dto.dart';
import 'store_form_body.dart';
import 'store_form_save_logic.dart';

/// Opens the [StoreFormSheet] as a modal bottom sheet.
///
/// SL-1: [areas] parameter removed — Province dropdown replaced Area dropdown.
void showStoreFormSheet({
  required BuildContext context,
  StoreDto? store,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: false,
    builder: (ctx) => StoreFormSheet(store: store, onSaved: onSaved),
  );
}

class StoreFormSheet extends StatefulWidget {
  final StoreDto? store;
  final VoidCallback onSaved;

  const StoreFormSheet({super.key, this.store, required this.onSaved});

  @override
  State<StoreFormSheet> createState() => _StoreFormSheetState();
}

class _StoreFormSheetState extends State<StoreFormSheet>
    with StoreFormSaveLogic {
  // ── Controllers ────────────────────────────────────────────────────────────
  @override
  late final TextEditingController nameCtrl;
  @override
  late final TextEditingController addressCtrl;
  @override
  late final TextEditingController latCtrl;
  @override
  late final TextEditingController lngCtrl;
  @override
  late final TextEditingController districtCtrl;
  @override
  late final TextEditingController wardCtrl;
  @override
  late final TextEditingController streetCtrl;

  late final MapController _mapCtrl;

  // ── Mixin contract ─────────────────────────────────────────────────────────
  @override
  String? selectedProvince;

  @override
  StoreDto? get storeToEdit => widget.store;

  @override
  VoidCallback get onSaved => widget.onSaved;

  // ── Map state ──────────────────────────────────────────────────────────────
  LatLng? _markerPos;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.store?.name ?? '');
    addressCtrl = TextEditingController(text: widget.store?.address ?? '');
    latCtrl = TextEditingController(
      text: widget.store?.gpsLat?.toString() ?? '',
    );
    lngCtrl = TextEditingController(
      text: widget.store?.gpsLng?.toString() ?? '',
    );
    selectedProvince = widget.store?.addressProvince;
    districtCtrl = TextEditingController(
      text: widget.store?.addressDistrict ?? '',
    );
    wardCtrl = TextEditingController(text: widget.store?.addressWard ?? '');
    streetCtrl = TextEditingController(
      text: widget.store?.addressStreet ?? '',
    );

    _mapCtrl = MapController();

    final initLat = double.tryParse(latCtrl.text);
    final initLng = double.tryParse(lngCtrl.text);
    if (initLat != null && initLng != null) {
      _markerPos = LatLng(initLat, initLng);
    }

    loadProvinces();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    districtCtrl.dispose();
    wardCtrl.dispose();
    streetCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: isDirty,
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: StoreFormBody(
          isEdit: widget.store != null,
          isSaving: isSaving,
          provincesLoading: provincesLoading,
          nameCtrl: nameCtrl,
          addressCtrl: addressCtrl,
          districtCtrl: districtCtrl,
          wardCtrl: wardCtrl,
          streetCtrl: streetCtrl,
          latCtrl: latCtrl,
          lngCtrl: lngCtrl,
          provinces: provinces,
          selectedProvince: selectedProvince,
          markerPos: _markerPos,
          mapController: _mapCtrl,
          onMarkDirty: markDirty,
          onProvinceChanged: (v) {
            setState(() => selectedProvince = v);
            markDirty();
          },
          onMapTap: (tapPos, latlng) {
            setState(() {
              _markerPos = latlng;
              latCtrl.text = latlng.latitude.toStringAsFixed(6);
              lngCtrl.text = latlng.longitude.toStringAsFixed(6);
            });
            markDirty();
          },
          onSave: saveStore,
        ),
      ),
    );
  }
}
