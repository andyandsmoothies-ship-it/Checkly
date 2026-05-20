import 'package:flutter/material.dart';

import '../../../_shared/constants/app_roles.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import 'shared/store_picker.dart';

/// Pure presentation widget for the user edit form.
/// Extracted from [UserEditSheet] to comply with architectural file-size limits.
class UserEditSheetBody extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDirty;
  final TextEditingController fullNameCtrl;
  final String? selectedRole;
  final String? selectedStoreId;
  final List<String> selectedStoreIds;
  final List<Map<String, dynamic>> assignableStores;
  final bool isLoadingStores;
  final bool showAssignedStores;

  // Callbacks
  final VoidCallback onMarkDirty;
  final void Function(String?) onRoleChanged;
  final void Function(String?) onStoreChanged;
  final void Function(bool) onShowAssignedStoresChanged;
  final void Function(bool?, String) onStoreSelectionChanged;
  final VoidCallback onSave;
  final VoidCallback onResetPassword;

  const UserEditSheetBody({
    super.key,
    required this.user,
    required this.isDirty,
    required this.fullNameCtrl,
    required this.selectedRole,
    required this.selectedStoreId,
    required this.selectedStoreIds,
    required this.assignableStores,
    required this.isLoadingStores,
    required this.showAssignedStores,
    required this.onMarkDirty,
    required this.onRoleChanged,
    required this.onStoreChanged,
    required this.onShowAssignedStoresChanged,
    required this.onStoreSelectionChanged,
    required this.onSave,
    required this.onResetPassword,
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
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: fullNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Role dropdown ─────────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                borderRadius: BorderRadius.circular(12),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AppRoles.admin, child: Text('Admin')),
                  DropdownMenuItem(value: AppRoles.auditor, child: Text('Auditor')),
                  DropdownMenuItem(
                    value: AppRoles.storeManager,
                    child: Text('Store Manager'),
                  ),
                  DropdownMenuItem(
                    value: AppRoles.areaManager,
                    child: Text('Area Manager'),
                  ),
                ],
                onChanged: onRoleChanged,
              ),

              // ── Store Picker ─────────────────────────────────────────────
              StorePicker(
                selectedRole: selectedRole,
                selectedStoreId: selectedStoreId,
                selectedStoreIds: selectedStoreIds,
                assignableStores: assignableStores,
                isLoadingStores: isLoadingStores,
                showAssignedStores: showAssignedStores,
                onStoreChanged: onStoreChanged,
                onShowAssignedStoresChanged: onShowAssignedStoresChanged,
                onStoreSelectionChanged: (id, checked) =>
                    onStoreSelectionChanged(checked, id),
              ),
              const SizedBox(height: 20),

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 12),

              // ── Reset Password button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onResetPassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
