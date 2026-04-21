import 'package:flutter/material.dart';

import '../../../_shared/widgets/unsaved_changes_guard.dart';
import 'dropdown_card.dart';

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
  late String? selectedStoreId;
  late String? selectedAreaId;
  List<Map<String, dynamic>> assignableStores = [];
  bool isDirty = false;

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

    // Pre-load stores if the user is already a store_manager
    if (selectedRole == 'store_manager') {
      _loadStores();
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  /// Loads assignable stores and shows a SnackBar on network failure.
  /// Silent empty-list is worse than a visible error — Sentinel observation.
  Future<void> _loadStores() async {
    try {
      final stores = await widget.loadStores();
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
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user['email'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'auditor', child: Text('Auditor')),
                DropdownMenuItem(
                  value: 'store_manager',
                  child: Text('Store Manager'),
                ),
                DropdownMenuItem(
                  value: 'area_manager',
                  child: Text('Area Manager'),
                ),
              ],
              onChanged: (v) async {
                _markDirty();
                // Lazy-load stores only on the first switch to store_manager
                if (v == 'store_manager' && selectedRole != 'store_manager') {
                  await _loadStores(); // error-handled, shows SnackBar on failure
                }
                if (mounted) {
                  setState(() {
                    selectedRole = v;
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
                items: assignableStores.map((s) {
                  final mgr = s['managerName'] as String?;
                  return (
                    id: s['id'] as String,
                    label: s['name'] as String,
                    subtitle: mgr != null ? 'SM: $mgr' : 'Vacant',
                  );
                }).toList(),
                onChanged: (v) {
                  _markDirty();
                  setState(() => selectedStoreId = v);
                },
              ),
            ],

            // ── Area picker (area_manager only) ──────────────────────────
            if (selectedRole == 'area_manager') ...[
              const SizedBox(height: 12),
              DropdownCard(
                icon: Icons.map_outlined,
                label: 'ASSIGNED AREA',
                hint: 'Select an area',
                value: selectedAreaId,
                itemIcon: Icons.map_outlined,
                nullable: true,
                items: widget.areas.map((a) {
                  final mgr = a['managerName'] as String?;
                  return (
                    id: a['id'] as String,
                    label: a['name'] as String,
                    subtitle: mgr != null ? 'AM: $mgr' : 'Vacant',
                  );
                }).toList(),
                onChanged: (v) {
                  _markDirty();
                  setState(() => selectedAreaId = v);
                },
              ),
            ],
            const SizedBox(height: 20),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onSave(
                  userId: widget.user['id'] as String,
                  fullName: _fullNameCtrl.text.trim().isEmpty
                      ? null
                      : _fullNameCtrl.text.trim(),
                  role: selectedRole,
                  storeId: selectedStoreId,
                  areaId: selectedAreaId,
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),

            // ── Reset Password button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onResetPassword(
                  context,
                  widget.user['id'] as String,
                  widget.user['fullName'] as String? ?? 'this user',
                ),
                icon: const Icon(Icons.lock_reset),
                label: const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
