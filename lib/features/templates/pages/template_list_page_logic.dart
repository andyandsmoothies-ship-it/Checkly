// ignore_for_file: invalid_use_of_protected_member
part of 'template_list_page.dart';

extension _TemplateListLogic on _TemplateListPageState {
  /// Shows a popup menu with 2 creation options.
  /// Uses showMenu() — never wraps FAB in PopupMenuButton (Gotcha #2).
  void _showCreateMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.swan, width: 2),
      ),
      items: [
        PopupMenuItem(
          value: 'classic',
          child: ListTile(
            leading: const Icon(Icons.build_outlined, color: AppColors.macaw),
            title: const Text(
              'Classic Builder',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: AppColors.eel,
              ),
            ),
            subtitle: const Text(
              'Full control over every detail',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: AppColors.wolf,
              ),
            ),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'wizard',
          child: ListTile(
            leading: const Icon(Icons.auto_fix_high, color: AppColors.fox),
            title: const Text(
              'Guided Creation',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                color: AppColors.eel,
              ),
            ),
            subtitle: const Text(
              'Step-by-step for quick setup',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: AppColors.wolf,
              ),
            ),
            dense: true,
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    switch (result) {
      case 'classic':
        context.push('/templates/new');
      case 'wizard':
        context.push('/templates/wizard');
    }
  }

  List<TemplateDto> get _filtered {
    final manager = _di<TemplateManager>();
    var items = manager.templates.value;

    // Filter by status (published = isActive, draft = !isActive)
    if (_filter == 'published') {
      items = items.where((t) => t.isActive).toList();
    } else if (_filter == 'draft') {
      items = items.where((t) => !t.isActive).toList();
    }

    // Filter by search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.type.toLowerCase().contains(q),
          )
          .toList();
    }

    return items;
  }

  /// Groups filtered templates by type, respecting _typeOrder.
  /// Always includes all types from _typeOrder even if empty (Fix 4).
  Map<String, List<TemplateDto>> get _groupedByType {
    final items = _filtered;
    // Seed with all known types so empty sections appear
    final groups = <String, List<TemplateDto>>{
      for (final type in _typeOrder) type: [],
    };
    for (final t in items) {
      groups.putIfAbsent(t.type, () => []).add(t);
    }
    // Sort keys by _typeOrder, unknowns at end
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final ia = _typeOrder.indexOf(a);
        final ib = _typeOrder.indexOf(b);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });
    return {for (final k in sortedKeys) k: groups[k]!};
  }

  int _countByFilter(String filter) {
    final all = _di<TemplateManager>().templates.value;
    if (filter == 'all') return all.length;
    if (filter == 'published') return all.where((t) => t.isActive).length;
    if (filter == 'draft') return all.where((t) => !t.isActive).length;
    return 0;
  }
}
