import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

    double? gpsLat;
    final latText = latCtrl.text.trim();
    if (latText.isNotEmpty) {
      final parsed = double.tryParse(latText);
      if (parsed == null) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Latitude must be a valid number',
          ),
        );
        return;
      }
      if (parsed < -90 || parsed > 90) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Latitude must be between -90 and 90 degrees',
          ),
        );
        return;
      }
      gpsLat = parsed;
    }

    double? gpsLng;
    final lngText = lngCtrl.text.trim();
    if (lngText.isNotEmpty) {
      final parsed = double.tryParse(lngText);
      if (parsed == null) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Longitude must be a valid number',
          ),
        );
        return;
      }
      if (parsed < -180 || parsed > 180) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'Longitude must be between -180 and 180 degrees',
          ),
        );
        return;
      }
      gpsLng = parsed;
    }

    setState(() => isSaving = true);

    final province = selectedProvince;
    final district = districtCtrl.text.trim().isNotEmpty
        ? districtCtrl.text.trim()
        : null;
    final ward = wardCtrl.text.trim().isNotEmpty ? wardCtrl.text.trim() : null;
    final street = streetCtrl.text.trim().isNotEmpty
        ? streetCtrl.text.trim()
        : null;

    try {
      if (storeToEdit?.id != null) {
        await _di<StoreApiService>().updateStore(
          storeToEdit!.id,
          name: name,
          address: addressCtrl.text.trim().isNotEmpty
              ? addressCtrl.text.trim()
              : null,
          gpsLat: gpsLat,
          gpsLng: gpsLng,
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
          gpsLat: gpsLat,
          gpsLng: gpsLng,
          province: province,
          district: district,
          ward: ward,
          street: street,
        );
      }

      if (mounted) {
        setState(() {
          isDirty = false;
          isSaving = false;
        });
        void pop() {
          if (mounted) {
            Navigator.maybePop(context);
          }
        }
        if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          WidgetsBinding.instance.addPostFrameCallback((_) => pop());
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) => pop());
          });
        }

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
