import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';

/// Bottom sheet for creating a new user.
///
/// Self-contained for inline validation and field-level error routing
/// (e.g. 409 → email field). On success, pops with [true] so the caller
/// knows to refresh the user list.
///
/// API call is delegated via [onCreate] — the sheet never imports [AdminApiService]
/// directly, keeping it decoupled from the DI layer.
class UserCreateSheet extends StatefulWidget {
  final List<Map<String, dynamic>> areas;

  final Future<List<Map<String, dynamic>>> Function({
    String? assignableAs,
    String? exceptUser,
  }) loadStores;

  /// Called on form submit with all validated field values.
  /// Should throw a [DioException] on API error so the sheet can route it.
  final Future<void> Function({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? storeId,
    String? areaId,
  }) onCreate;

  const UserCreateSheet({
    super.key,
    required this.areas,
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

  String selectedRole = 'auditor';
  String? selectedStoreId;
  String? selectedAreaId;
  List<Map<String, dynamic>> assignableStores = [];

  bool isSubmitting = false;
  bool isDirty = false;
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

  void _markDirty() {
    if (!isDirty) setState(() => isDirty = true);
  }

  Future<void> _submit() async {
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
        areaId: selectedAreaId,
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Signal page to refresh
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
      if (e is DioException) {
        statusCode = e.response?.statusCode;
        final data = e.response?.data;
        serverMsg = data is Map
            ? data['message']?.toString()
            : data?.toString() ?? e.message;
      } else {
        serverMsg = e.toString();
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
    return UnsavedChangesGuard(
      isDirty: isDirty,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New User',
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

              // ── Full Name ────────────────────────────────────────────────
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  errorText: nameError,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  _markDirty();
                  if (nameError != null) setState(() => nameError = null);
                },
              ),
              const SizedBox(height: 12),

              // ── Email ────────────────────────────────────────────────────
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  errorText: emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  _markDirty();
                  if (emailError != null) setState(() => emailError = null);
                },
              ),
              const SizedBox(height: 12),

              // ── Temporary Password ───────────────────────────────────────
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Temporary Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: passwordError,
                  helperText: passwordError == null
                      ? 'Min 8 chars: uppercase, digit, special char'
                      : null,
                ),
                obscureText: true,
                onChanged: (_) {
                  if (passwordError != null) setState(() => passwordError = null);
                },
              ),
              const SizedBox(height: 12),

              // ── Role ─────────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                borderRadius: BorderRadius.circular(12),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'auditor', child: Text('Auditor')),
                  DropdownMenuItem(
                    value: 'store_manager',
                    child: Text('Store Manager'),
                  ),
                  DropdownMenuItem(
                    value: 'area_manager',
                    child: Text('Area Manager'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) async {
                  // Lazy-load stores on first switch to store_manager
                  if (v == 'store_manager' && selectedRole != 'store_manager') {
                    final stores = await widget.loadStores(
                      assignableAs: 'store_manager',
                    );
                    if (mounted) setState(() => assignableStores = stores);
                  }
                  if (mounted) {
                    setState(() {
                      selectedRole = v ?? 'auditor';
                      if (v == 'admin' || v == 'auditor') {
                        selectedStoreId = null;
                        selectedAreaId = null;
                      } else if (v == 'store_manager') {
                        selectedAreaId = null;
                      } else if (v == 'area_manager') {
                        selectedStoreId = null;
                      }
                    });
                  }
                },
              ),

              // ── Store dropdown (store_manager only) ──────────────────────
              if (selectedRole == 'store_manager') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStoreId,
                  borderRadius: BorderRadius.circular(12),
                  decoration: const InputDecoration(
                    labelText: 'Assigned Store',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ...assignableStores.map(
                      (s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] as String),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => selectedStoreId = v),
                ),
              ],

              // ── Area dropdown (area_manager only) ────────────────────────
              if (selectedRole == 'area_manager') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAreaId,
                  borderRadius: BorderRadius.circular(12),
                  decoration: const InputDecoration(
                    labelText: 'Assigned Area',
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
                  onChanged: (v) => setState(() => selectedAreaId = v),
                ),
              ],
              const SizedBox(height: 20),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(isSubmitting ? 'Creating...' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
