import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_it/get_it.dart';

import '../../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../../../_shared/services/geocoding_service.dart';
import '../../../../_shared/exceptions/app_error.dart';
import '../../../../_shared/services/error_display_service.dart';
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
    enableDrag: false,
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
    streetCtrl = TextEditingController(text: widget.store?.addressStreet ?? '');

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
          isGeocoding: _isGeocoding,
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
          onMapTap: _handleMapTap,
          onLocateOnMap: _handleLocateOnMap,
          onSave: saveStore,
        ),
      ),
    );
  }

  bool _isGeocoding = false;

  String _removeDiacritics(String str) {
    const vietnamese = 'aAeEoOuUiIdDyY';
    final vietnameseRegex = [
      RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'),
      RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'),
      RegExp(r'[èéẹẻẽêềếệểễ]'),
      RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'),
      RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'),
      RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'),
      RegExp(r'[ùúụủũưừứựửữ]'),
      RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'),
      RegExp(r'[ìíịỉĩ]'),
      RegExp(r'[ÌÍỊỈĨ]'),
      RegExp(r'[đ]'),
      RegExp(r'[Đ]'),
      RegExp(r'[ỳýỵỷỹ]'),
      RegExp(r'[ỲÝỴỶỸ]'),
    ];

    var result = str;
    for (var i = 0; i < vietnameseRegex.length; i++) {
      result = result.replaceAll(vietnameseRegex[i], vietnamese[i]);
    }
    return result;
  }

  String? _normalizeProvince(String rawProvince) {
    final cleanRaw = _removeDiacritics(rawProvince.toLowerCase())
        .replaceAll('thanh pho', '')
        .replaceAll('tinh', '')
        .replaceAll('city', '')
        .replaceAll('province', '')
        .trim();

    for (final p in provinces) {
      final cleanP = _removeDiacritics(p.toLowerCase())
          .replaceAll('thanh pho', '')
          .replaceAll('tinh', '')
          .replaceAll('city', '')
          .replaceAll('province', '')
          .trim();
      if (cleanP == cleanRaw || cleanP.contains(cleanRaw) || cleanRaw.contains(cleanP)) {
        return p;
      }
    }
    return null;
  }

  void _showWarningSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address name not found, but map coordinates saved'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleMapTap(TapPosition tapPos, LatLng latlng) async {
    print('DEBUG: _handleMapTap called with latlng=$latlng, isSaving=$isSaving, _isGeocoding=$_isGeocoding');
    if (isSaving || _isGeocoding) return;
    setState(() {
      _isGeocoding = true;
      _markerPos = latlng;
      latCtrl.text = latlng.latitude.toStringAsFixed(6);
      lngCtrl.text = latlng.longitude.toStringAsFixed(6);
    });
    markDirty();

    try {
      final geocodingService = GetIt.instance<GeocodingService>();
      final address = await geocodingService.reverseGeocode(latlng);
      print('DEBUG: geocodingService.reverseGeocode returned $address');
      if (address != null) {
        setState(() {
          if (address.street != null && address.street!.isNotEmpty) {
            streetCtrl.text = address.street!;
          }
          if (address.ward != null && address.ward!.isNotEmpty) {
            wardCtrl.text = address.ward!;
          }
          if (address.district != null && address.district!.isNotEmpty) {
            districtCtrl.text = address.district!;
          }
          if (address.province != null && address.province!.isNotEmpty) {
            print('DEBUG: provinces list = $provinces');
            print('DEBUG: address.province = ${address.province}');
            final normalizedProvince = _normalizeProvince(address.province!);
            print('DEBUG: normalizedProvince = $normalizedProvince');
            if (normalizedProvince != null) {
              selectedProvince = normalizedProvince;
              print('DEBUG: selectedProvince set to $selectedProvince');
            }
          }
          if (address.displayName != null && address.displayName!.isNotEmpty) {
            addressCtrl.text = address.displayName!;
          }
        });
      } else {
        _showWarningSnackBar();
      }
    } catch (e, s) {
      print('DEBUG: reverseGeocode caught exception: $e\n$s');
      _showWarningSnackBar();
    } finally {
      if (mounted) {
        await Future.delayed(Duration.zero);
        if (mounted) {
          setState(() {
            _isGeocoding = false;
          });
        }
      }
    }
  }

  Future<void> _handleLocateOnMap() async {
    if (isSaving || _isGeocoding) return;

    final List<String> addressParts = [];
    if (streetCtrl.text.trim().isNotEmpty) addressParts.add(streetCtrl.text.trim());
    if (wardCtrl.text.trim().isNotEmpty) addressParts.add(wardCtrl.text.trim());
    if (districtCtrl.text.trim().isNotEmpty) addressParts.add(districtCtrl.text.trim());
    if (selectedProvince != null && selectedProvince!.isNotEmpty) addressParts.add(selectedProvince!);

    final query = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : addressCtrl.text.trim();

    if (query.isEmpty) {
      GetIt.instance<ErrorDisplayService>().show(
        const AppError(
          code: 'validation_error',
          message: 'Please enter address details to locate on map',
        ),
      );
      return;
    }

    setState(() {
      _isGeocoding = true;
    });

    try {
      final geocodingService = GetIt.instance<GeocodingService>();
      final point = await geocodingService.geocode(query);
      if (point != null) {
        setState(() {
          _markerPos = point;
          latCtrl.text = point.latitude.toStringAsFixed(6);
          lngCtrl.text = point.longitude.toStringAsFixed(6);
        });
        _mapCtrl.move(point, 14.0);
        markDirty();
      } else {
        GetIt.instance<ErrorDisplayService>().show(
          const AppError(
            code: 'geocoding_error',
            message: 'Could not find coordinates for this address',
          ),
        );
      }
    } catch (e) {
      GetIt.instance<ErrorDisplayService>().show(
        AppError(
          code: 'geocoding_error',
          message: e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        await Future.delayed(Duration.zero);
        if (mounted) {
          setState(() {
            _isGeocoding = false;
          });
        }
      }
    }
  }
}
