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
          : (role == 'store_manager' ? 'store_manager' : (role == 'area_manager' ? 'area_manager' : null));
      final stores = await widget.loadStores(
        assignableAs: assignableAs,
        exceptUser: role == 'store_manager' ? widget.user['id'] as String : null,
      );
      if (mounted) {
        setState(() {
          assignableStores = stores;
          _isLoadingStores = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStores = false);
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

            // ── Direct Store Assignments (area_manager only) ──────────────────────────
            if (selectedRole == 'area_manager') ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Show assigned stores'),
                value: showAssignedStores,
                onChanged: (val) {
                  setState(() => showAssignedStores = val);
                  _loadStores(selectedRole!);
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
                child: _isLoadingStores
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : assignableStores.isEmpty
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
                              _markDirty();
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
                  assignedStoreIds: selectedRole == 'area_manager' && _selectedStoreIds.isNotEmpty
                      ? _selectedStoreIds
                      : null,
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
      ),
    );
  }
}
