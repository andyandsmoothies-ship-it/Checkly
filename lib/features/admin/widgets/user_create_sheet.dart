import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import 'dropdown_card.dart';
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
  final List<Map<String, dynamic>> areas;

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
    String? areaId,
    List<String>? assignedStoreIds,
    bool? forceReassign,
  })
  onCreate;

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
          : (role == 'store_manager' ? 'store_manager' : (role == 'area_manager' ? 'area_manager' : null));
      final stores = await widget.loadStores(
        assignableAs: assignableAs,
      );
      if (mounted) setState(() => assignableStores = stores);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load stores. Check your connection.'),
          ),
        );
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
        areaId: null, // Removed Area for AM
        assignedStoreIds: selectedRole == 'area_manager' && _selectedStoreIds.isNotEmpty 
            ? _selectedStoreIds 
            : null,
        forceReassign: forceReassign,
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

      if (statusCode == 409 && responseData is Map && responseData['existingManagerName'] != null) {
        if (mounted) setState(() => isSubmitting = false);
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
                  if (passwordError != null) {
                    setState(() => passwordError = null);
                  }
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
                  // Lazy-load stores on first switch to a role that needs them
                  if ((v == 'store_manager' || v == 'area_manager') && 
                      selectedRole != v) {
                    await _loadStores(v!); // error-handled, shows SnackBar on failure
                  }
                  if (mounted) {
                    setState(() {
                      selectedRole = v ?? 'auditor';
                      if (v == 'admin' || v == 'auditor') {
                        selectedStoreId = null;
                        _selectedStoreIds.clear();
                      } else if (v == 'store_manager') {
                        _selectedStoreIds.clear();
                      } else if (v == 'area_manager') {
                        selectedStoreId = null;
                      }
                    });
                  }
                },
              ),

              // ── Store picker (store_manager only) ──────────────────────────
              if (selectedRole == 'store_manager') ...[
                const SizedBox(height: 12),
                DropdownCard(
                  icon: Icons.store_outlined,
                  label: 'ASSIGNED STORE',
                  hint: 'Select a store',
                  value: selectedStoreId,
                  itemIcon: Icons.store_outlined,
                  nullable: true,
                  items: assignableStores
                      .map(
                        (s) => (
                          id: s['id'] as String,
                          label: s['name'] as String,
                          subtitle: null as String?,
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedStoreId = v),
                ),
              ],

              // ── Direct Store Assignments (area_manager only) ──────────────────────────
              if (selectedRole == 'area_manager') ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Show assigned stores'),
                  value: showAssignedStores,
                  onChanged: (val) {
                    setState(() => showAssignedStores = val);
                    _loadStores(selectedRole);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Text(
                  'DIRECT STORE ASSIGNMENTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: assignableStores.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active stores found.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: assignableStores.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final store = assignableStores[index];
                            final id = store['id'] as String;
                            final name = store['name'] as String;
                            final isSelected = _selectedStoreIds.contains(id);

                            return CheckboxListTile(
                              title: Text(name),
                              value: isSelected,
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedStoreIds.add(id);
                                  } else {
                                    _selectedStoreIds.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
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
