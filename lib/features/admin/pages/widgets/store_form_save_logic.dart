import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/exceptions/app_error.dart';
import '../../../../_shared/services/error_display_service.dart';
import '../../../stores/model/store_dto.dart';
import '../../../stores/services/store_api_service.dart';

/// Mixin that provides save and province-load logic for [StoreFormSheet].
///
/// Requires the host State to expose the controllers and flags listed below.
mixin StoreFormSaveLogic<T extends StatefulWidget> on State<T> {
  // ── Controllers the host State must declare ──────────────────────────────
  TextEditingController get nameCtrl;
  TextEditingController get addressCtrl;
  TextEditingController get latCtrl;
  TextEditingController get lngCtrl;
  TextEditingController get districtCtrl;
  TextEditingController get wardCtrl;
  TextEditingController get streetCtrl;

  // ── Mutable state the host exposes ───────────────────────────────────────
  String? get selectedProvince;
  StoreDto? get storeToEdit;
  VoidCallback get onSaved;

  // ── Flags written back via setState ──────────────────────────────────────
  List<String> provinces = [];
  bool provincesLoading = true;
  bool isSaving = false;
  bool isDirty = false;

  final _di = GetIt.instance;

  // ── Province loading ──────────────────────────────────────────────────────

  Future<void> loadProvinces() async {
    try {
      final list = await _di<StoreApiService>().fetchProvinces();
      if (mounted) setState(() => provinces = list);
    } catch (_) {
      // Non-fatal: Province dropdown stays empty; user can still save form
    } finally {
      if (mounted) setState(() => provincesLoading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveStore() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _di<ErrorDisplayService>().show(
        const AppError(
          code: 'validation_error',
          message: 'Store name is required',
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final province = selectedProvince;
    final district =
        districtCtrl.text.trim().isNotEmpty ? districtCtrl.text.trim() : null;
    final ward =
        wardCtrl.text.trim().isNotEmpty ? wardCtrl.text.trim() : null;
    final street =
        streetCtrl.text.trim().isNotEmpty ? streetCtrl.text.trim() : null;

    try {
      if (storeToEdit?.id != null) {
        await _di<StoreApiService>().updateStore(
          storeToEdit!.id,
          name: name,
          address: addressCtrl.text.trim().isNotEmpty
              ? addressCtrl.text.trim()
              : null,
          gpsLat: double.tryParse(latCtrl.text.trim()),
          gpsLng: double.tryParse(lngCtrl.text.trim()),
          province: province,
          district: district,
          ward: ward,
          street: street,
        );
      } else {
        await _di<StoreApiService>().createStore(
          name: name,
          address: addressCtrl.text.trim().isNotEmpty
              ? addressCtrl.text.trim()
              : null,
          gpsLat: double.tryParse(latCtrl.text.trim()),
          gpsLng: double.tryParse(lngCtrl.text.trim()),
          province: province,
          district: district,
          ward: ward,
          street: street,
        );
      }

      if (mounted) {
        isDirty = false;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              storeToEdit?.id != null ? 'Store updated' : 'Store created',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        if (e is DioException) {
          _di<ErrorDisplayService>().show(AppError.fromDioException(e));
        } else {
          _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
        }
      }
    }
  }

  void markDirty() {
    if (!isDirty) setState(() => isDirty = true);
  }
}
