import 'package:flutter/material.dart';

import '../dropdown_card.dart';

/// A shared presentation widget for selecting stores.
/// Renders a single dropdown for Store Managers or a multi-select list
/// for Area Managers.
class StorePicker extends StatelessWidget {
  final String? selectedRole;
  final String? selectedStoreId;
  final List<String> selectedStoreIds;
  final List<Map<String, dynamic>> assignableStores;
  final bool isLoadingStores;
  final bool showAssignedStores;

  final void Function(String?) onStoreChanged;
  final void Function(bool) onShowAssignedStoresChanged;
  final void Function(String, bool?) onStoreSelectionChanged;

  const StorePicker({
    super.key,
    required this.selectedRole,
    required this.selectedStoreId,
    required this.selectedStoreIds,
    required this.assignableStores,
    required this.isLoadingStores,
    required this.showAssignedStores,
    required this.onStoreChanged,
    required this.onShowAssignedStoresChanged,
    required this.onStoreSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRole != 'store_manager' && selectedRole != 'area_manager') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
            onChanged: onStoreChanged,
          ),
        ],

        // ── Direct Store Assignments (area_manager only) ──────────────────────────
        if (selectedRole == 'area_manager') ...[
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Show assigned stores'),
            value: showAssignedStores,
            onChanged: onShowAssignedStoresChanged,
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
            child: isLoadingStores
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
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final store = assignableStores[index];
                      final id = store['id'] as String;
                      final name = store['name'] as String;
                      final isSelected = selectedStoreIds.contains(id);

                      return CheckboxListTile(
                        title: Text(name),
                        value: isSelected,
                        onChanged: (checked) =>
                            onStoreSelectionChanged(id, checked),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
