import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../locator.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import 'user_edit_sheet_body.dart';

/// Bottom sheet for editing an existing user's role, store and area assignment.
///
/// Intentionally stateful — manages isDirty flag and the assignable-stores
/// list independently of the page. All API calls are delegated back to the
/// page via [onSave] and [onResetPassword] callbacks so that the page's
/// [_saveUser] and [_loadData] remain the single source of truth.
class UserEditSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> areas;

  /// Returns all stores the page knows how to load. Called when role switches
  /// to store_manager.
  final Future<List<Map<String, dynamic>>> Function({
    String? assignableAs,
    String? exceptUser,
  })
  loadStores;

  /// Called when the user taps Save. Implementation lives in the Page so that
  /// the page keeps ownership of Navigator.pop() + _loadData() + 409 dialog.
  final Future<void> Function({
    required String userId,
    String? fullName,
    String? role,
    String? storeId,
    String? areaId,
    List<String>? assignedStoreIds,
  })
  onSave;

  /// Called when the user taps Reset Password. The Page shows its dialog.
  /// First arg is this sheet's BuildContext so the dialog can pop the sheet.
  final void Function(BuildContext sheetCtx, String userId, String userName)
  onResetPassword;

  const UserEditSheet({
    super.key,
    required this.user,
    required this.areas,
    required this.loadStores,
    required this.onSave,
    required this.onResetPassword,
  });

  @override
  State<UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<UserEditSheet> {
  late final TextEditingController _fullNameCtrl;
  late String? selectedRole;
  String? selectedStoreId;
  String? selectedAreaId;
  List<String> _selectedStoreIds = [];
  List<Map<String, dynamic>> assignableStores = [];
  bool _isLoadingStores = false;
  bool isDirty = false;
  bool showAssignedStores = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(
      text: widget.user['fullName'] as String?,
    );
    _fullNameCtrl.addListener(_markDirty);
    selectedRole = widget.user['role'] as String?;
    selectedStoreId = widget.user['storeId'] as String?;
    selectedAreaId = widget.user['areaId'] as String?;

    if (widget.user['assignedStoreIds'] != null) {
      _selectedStoreIds = (widget.user['assignedStoreIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    // Pre-load stores if the user is already a store_manager or area_manager
    if (selectedRole == 'store_manager' || selectedRole == 'area_manager') {
      _loadStores(selectedRole!);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  /// Loads assignable stores and shows a SnackBar on network failure.
  /// silent empty-list is worse than a visible error — Sentinel observation.
  Future<void> _loadStores(String role) async {
    if (mounted) setState(() => _isLoadingStores = true);
    try {
      final String? assignableAs = showAssignedStores
          ? null
          : (role == 'store_manager'
                ? 'store_manager'
                : (role == 'area_manager' ? 'area_manager' : null));
      final stores = await widget.loadStores(
        assignableAs: assignableAs,
        exceptUser: role == 'store_manager'
            ? widget.user['id'] as String
            : null,
      );
      if (mounted) {
        setState(() {
          assignableStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStores = false);
        if (e is DioException) {
          di<ErrorDisplayService>().show(AppError.fromDioException(e));
        } else {
          di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
        }
      }
    }
  }

  void _markDirty() {
    if (!isDirty) setState(() => isDirty = true);
  }

  @override
  Widget build(BuildContext context) {
    return UserEditSheetBody(
      user: widget.user,
      isDirty: isDirty,
      fullNameCtrl: _fullNameCtrl,
      selectedRole: selectedRole,
      selectedStoreId: selectedStoreId,
      selectedAreaId: selectedAreaId,
      selectedStoreIds: _selectedStoreIds,
      assignableStores: assignableStores,
      isLoadingStores: _isLoadingStores,
      showAssignedStores: showAssignedStores,
      onMarkDirty: _markDirty,
      onRoleChanged: (v) async {
        _markDirty();
        // Lazy-load stores on the first switch to a role that needs them
        if ((v == 'store_manager' || v == 'area_manager') &&
            selectedRole != v) {
          await _loadStores(v!); // error-handled, shows SnackBar on failure
        }
        if (mounted) {
          setState(() {
            selectedRole = v;
            if (v == 'admin' || v == 'auditor') {
              selectedStoreId = null;
              selectedAreaId = null;
              _selectedStoreIds.clear();
            } else if (v == 'store_manager') {
              selectedAreaId = null;
              _selectedStoreIds.clear();
            } else if (v == 'area_manager') {
              selectedStoreId = null;
              selectedAreaId = null;
            }
          });
        }
      },
      onStoreChanged: (v) {
        _markDirty();
        setState(() => selectedStoreId = v);
      },
      onShowAssignedStoresChanged: (val) {
        setState(() => showAssignedStores = val);
        _loadStores(selectedRole!);
      },
      onStoreSelectionChanged: (bool? checked, String id) {
        _markDirty();
        setState(() {
          if (checked == true) {
            _selectedStoreIds.add(id);
          } else {
            _selectedStoreIds.remove(id);
          }
        });
      },
      onSave: () => widget.onSave(
        userId: widget.user['id'] as String,
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
        role: selectedRole,
        storeId: selectedStoreId,
        areaId: selectedAreaId,
        assignedStoreIds:
            selectedRole == 'area_manager' && _selectedStoreIds.isNotEmpty
            ? _selectedStoreIds
            : null,
      ),
      onResetPassword: () => widget.onResetPassword(
        context,
        widget.user['id'] as String,
        widget.user['fullName'] as String? ?? 'this user',
      ),
    );
  }
}
