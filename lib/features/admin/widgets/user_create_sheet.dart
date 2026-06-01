import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../_shared/constants/app_roles.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../locator.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import 'user_create_sheet_body.dart';
import 'user_management_dialogs.dart';

/// Bottom sheet for creating a new user.
///
/// Self-contained for inline validation and field-level error routing
/// (e.g. 409 → email field). On success, pops with [true] so the caller
/// knows to refresh the user list.
///
/// API call is delegated via [onCreate] — the sheet never imports [AdminApiService]
/// directly, keeping it decoupled from the DI layer.
class UserCreateSheet extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function({
    String? assignableAs,
    String? exceptUser,
  })
  loadStores;

  /// Called on form submit with all validated field values.
  /// Should throw a [DioException] on API error so the sheet can route it.
  final Future<void> Function({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? storeId,
    List<String>? assignedStoreIds,
    bool? forceReassign,
  })
  onCreate;

  const UserCreateSheet({
    super.key,
    required this.loadStores,
    required this.onCreate,
  });

  @override
  State<UserCreateSheet> createState() => _UserCreateSheetState();
}

class _UserCreateSheetState extends State<UserCreateSheet> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String selectedRole = AppRoles.auditor;
  String? selectedStoreId;
  final List<String> _selectedStoreIds = [];
  List<Map<String, dynamic>> assignableStores = [];

  bool isSubmitting = false;
  bool isDirty = false;
  bool showAssignedStores = false;
  String? nameError;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  /// Loads assignable stores and shows a SnackBar on network failure.
  /// silent empty-list is worse than a visible error — Sentinel observation.
  Future<void> _loadStores(String role) async {
    try {
      final String? assignableAs = showAssignedStores
          ? null
          : (role == AppRoles.storeManager
                ? AppRoles.storeManager
                : (role == AppRoles.areaManager ? AppRoles.areaManager : null));
      final stores = await widget.loadStores(assignableAs: assignableAs);
      if (mounted) setState(() => assignableStores = stores);
    } catch (e) {
      if (mounted) {
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

  Future<void> _submit({bool forceReassign = false}) async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Client-side required field validation
    String? nErr = name.isEmpty ? 'Full name is required' : null;
    String? eErr = email.isEmpty ? 'Email is required' : null;
    String? pErr = pass.isEmpty ? 'Password is required' : null;

    if (nErr != null || eErr != null || pErr != null) {
      setState(() {
        nameError = nErr;
        emailError = eErr;
        passwordError = pErr;
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      nameError = null;
      emailError = null;
      passwordError = null;
    });

    try {
      await widget.onCreate(
        email: email,
        password: pass,
        fullName: name,
        role: selectedRole,
        storeId: selectedStoreId,
        assignedStoreIds:
            selectedRole == AppRoles.areaManager && _selectedStoreIds.isNotEmpty
            ? _selectedStoreIds
            : null,
        forceReassign: forceReassign,
      );
      if (mounted) {
        Navigator.maybePop(context, true); // Signal page to refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      String? serverMsg;
      int? statusCode;
      dynamic responseData;
      if (e is DioException) {
        statusCode = e.response?.statusCode;
        responseData = e.response?.data;
        final data = e.response?.data;
        serverMsg = data is Map
            ? data['message']?.toString() ?? data['error']?.toString()
            : data?.toString() ?? e.message;
      } else {
        serverMsg = e.toString();
      }

      if (statusCode == 409 &&
          responseData is Map &&
          responseData['existingManagerName'] != null) {
        if (mounted) setState(() => isSubmitting = false);
        if (!mounted) return;
        final confirm = await UserManagementDialogs.confirmTransfer(
          context,
          responseData['existingManagerName'] as String,
        );
        if (confirm == true) {
          return _submit(forceReassign: true);
        }
        return;
      }

      // Route the error to the correct field
      final msg = serverMsg?.toLowerCase() ?? '';
      if (mounted) {
        setState(() {
          isSubmitting = false;
          if (statusCode == 409 || msg.contains('email')) {
            emailError = serverMsg;
          } else if (msg.contains('password')) {
            passwordError = serverMsg;
          } else {
            passwordError = serverMsg; // Fallback: last visible field
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserCreateSheetBody(
      isDirty: isDirty,
      nameCtrl: nameCtrl,
      emailCtrl: emailCtrl,
      passCtrl: passCtrl,
      nameError: nameError,
      emailError: emailError,
      passwordError: passwordError,
      selectedRole: selectedRole,
      selectedStoreId: selectedStoreId,
      selectedStoreIds: _selectedStoreIds,
      assignableStores: assignableStores,
      isSubmitting: isSubmitting,
      showAssignedStores: showAssignedStores,
      onMarkDirty: _markDirty,
      onNameErrorClear: (_) => setState(() => nameError = null),
      onEmailErrorClear: (_) => setState(() => emailError = null),
      onPasswordErrorClear: (_) => setState(() => passwordError = null),
      onRoleChanged: (v) async {
        if ((v == AppRoles.storeManager || v == AppRoles.areaManager) &&
            selectedRole != v) {
          await _loadStores(v);
        }
        if (mounted) {
          setState(() {
            selectedRole = v;
            if (v == AppRoles.admin || v == AppRoles.auditor) {
              selectedStoreId = null;
              _selectedStoreIds.clear();
            } else if (v == AppRoles.storeManager) {
              _selectedStoreIds.clear();
            } else if (v == AppRoles.areaManager) {
              selectedStoreId = null;
            }
          });
        }
      },
      onStoreChanged: (v) => setState(() => selectedStoreId = v),
      onShowAssignedStoresChanged: (val) {
        setState(() => showAssignedStores = val);
        _loadStores(selectedRole);
      },
      onStoreCheckChanged: (id, checked) {
        setState(() {
          if (checked == true) {
            _selectedStoreIds.add(id);
          } else {
            _selectedStoreIds.remove(id);
          }
        });
      },
      onSubmit: _submit,
    );
  }
}
