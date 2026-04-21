import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';

/// A selection card that opens a searchable modal bottom sheet.
///
/// This replaces the old [DropdownButtonFormField] approach which caused
/// "Contextual Claustrophobia" (covered the whole screen) and "Aesthetic Slop"
/// (no icons, no subtitles, generic look).
///
/// Each item is a plain record: `({String id, String label, String? subtitle})`.
class DropdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final List<({String id, String label, String? subtitle})> items;
  final IconData itemIcon;
  final ValueChanged<String?> onChanged;

  /// When true, shows a '— None —' row at the top of the picker sheet,
  /// which triggers [onChanged] with null (clear the selection).
  final bool nullable;

  const DropdownCard({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemIcon,
    required this.onChanged,
    this.nullable = false,
  });

  String? get _selectedLabel =>
      items.where((i) => i.id == value).firstOrNull?.label;

  Future<void> _openPicker(BuildContext context) async {
    // Return type is String? — null means the user chose '— None —'
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        label: label,
        itemIcon: itemIcon,
        items: items,
        selectedId: value,
        nullable: nullable,
      ),
    );
    // selected == null → sheet was dismissed without a pick (no-op)
    // selected == _kNoneValue → user tapped '— None —' (clear)
    if (selected == _kNoneValue) {
      onChanged(null);
    } else if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && _selectedLabel != null;

    return Card(
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label
              Row(
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppFonts.displayStyle(
                      fontSize: theme.textTheme.labelSmall?.fontSize,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Selection trigger row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? _selectedLabel! : hint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet Picker ───────────────────────────────────────────────────

/// Sentinel value used to signal 'user chose None' vs 'sheet dismissed'.
const _kNoneValue = '__none__';

class _PickerSheet extends StatefulWidget {
  final String label;
  final IconData itemIcon;
  final List<({String id, String label, String? subtitle})> items;
  final String? selectedId;
  final bool nullable;

  const _PickerSheet({
    required this.label,
    required this.itemIcon,
    required this.items,
    required this.selectedId,
    required this.nullable,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late List<({String id, String label, String? subtitle})> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
              .where((i) =>
                  i.label.toLowerCase().contains(query) ||
                  (i.subtitle?.toLowerCase().contains(query) ?? false))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(widget.itemIcon, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Select ${widget.label.toLowerCase().split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ')}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sticky search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: _filtered.isEmpty && !widget.nullable
                  ? Center(
                      child: Text(
                        'No results found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                      itemCount: _filtered.length + (widget.nullable ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 56,
                      ),
                      itemBuilder: (_, i) {
                        // First row is the "None" option when nullable
                        if (widget.nullable && i == 0) {
                          final isNoneSelected = widget.selectedId == null;
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isNoneSelected
                                    ? theme.colorScheme.errorContainer
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.block,
                                size: 18,
                                color: isNoneSelected
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              '— None —',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isNoneSelected ? FontWeight.w700 : FontWeight.normal,
                                color: isNoneSelected
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: isNoneSelected
                                ? Icon(Icons.check_circle_rounded,
                                    color: theme.colorScheme.error)
                                : null,
                            onTap: () => Navigator.pop(context, _kNoneValue),
                          );
                        }

                        final item = _filtered[i - (widget.nullable ? 1 : 0)];
                        final isSelected = item.id == widget.selectedId;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.itemIcon,
                              size: 18,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: item.subtitle != null
                              ? Text(
                                  item.subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () => Navigator.pop(context, item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
