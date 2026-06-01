import 'package:flutter/material.dart';

import '../../../_shared/constants/app_roles.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import 'shared/store_picker.dart';

/// Private body widget for [UserCreateSheet].
///
/// Receives all display state and callbacks from [_UserCreateSheetState] via
/// constructor parameters. It does NOT call GetIt, reach into any DAO, or
/// import any manager — it is a pure presentation widget.
class UserCreateSheetBody extends StatelessWidget {
  final bool isDirty;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String selectedRole;
  final String? selectedStoreId;
  final List<String> selectedStoreIds;
  final List<Map<String, dynamic>> assignableStores;
  final bool isSubmitting;
  final bool showAssignedStores;

  // Callbacks
  final VoidCallback onMarkDirty;
  final void Function(String?) onNameErrorClear;
  final void Function(String?) onEmailErrorClear;
  final void Function(String?) onPasswordErrorClear;
  final Future<void> Function(String) onRoleChanged;
  final void Function(String?) onStoreChanged;
  final void Function(bool) onShowAssignedStoresChanged;
  final void Function(String, bool?) onStoreCheckChanged;
  final Future<void> Function() onSubmit;

  const UserCreateSheetBody({
    super.key,
    required this.isDirty,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.nameError,
    required this.emailError,
    required this.passwordError,
    required this.selectedRole,
    required this.selectedStoreId,
    required this.selectedStoreIds,
    required this.assignableStores,
    required this.isSubmitting,
    required this.showAssignedStores,
    required this.onMarkDirty,
    required this.onNameErrorClear,
    required this.onEmailErrorClear,
    required this.onPasswordErrorClear,
    required this.onRoleChanged,
    required this.onStoreChanged,
    required this.onShowAssignedStoresChanged,
    required this.onStoreCheckChanged,
    required this.onSubmit,
  });

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
                  Expanded(
                    child: Text(
                      'Create New User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
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
                  onMarkDirty();
                  if (nameError != null) onNameErrorClear(null);
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
                  onMarkDirty();
                  if (emailError != null) onEmailErrorClear(null);
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
                  if (passwordError != null) onPasswordErrorClear(null);
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
                  DropdownMenuItem(
                    value: AppRoles.auditor,
                    child: Text('Auditor'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.storeManager,
                    child: Text('Store Manager'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.areaManager,
                    child: Text('Area Manager'),
                  ),
                  DropdownMenuItem(value: AppRoles.admin, child: Text('Admin')),
                ],
                onChanged: (v) => onRoleChanged(v ?? AppRoles.auditor),
              ),

              // ── Store Picker ─────────────────────────────────────────────
              StorePicker(
                selectedRole: selectedRole,
                selectedStoreId: selectedStoreId,
                selectedStoreIds: selectedStoreIds,
                assignableStores: assignableStores,
                isLoadingStores:
                    false, // Create form doesn't support lazy-loading stores
                showAssignedStores: showAssignedStores,
                onStoreChanged: onStoreChanged,
                onShowAssignedStoresChanged: onShowAssignedStoresChanged,
                onStoreSelectionChanged: onStoreCheckChanged,
              ),
              const SizedBox(height: 20),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.success,
                          ),
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
