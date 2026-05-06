import 'package:flutter/material.dart';

/// Speed-dial FAB matching the PWA's FloatingActionMenu.
/// Tapping the "+" opens a popup menu with role-gated actions.
///
/// **GOTCHA — Nested Scaffold:** Pages inside `_MainShell` (ShellRoute) are
/// wrapped in an outer Scaffold with `extendBody: true` and a 96px bottom nav.
/// This inner FAB MUST have `Padding(bottom: 80)` or it renders behind the
/// nav bar and becomes invisible. Do NOT remove this padding.
class ChecklyFab extends StatelessWidget {
  final bool isAdmin;
  final bool canCreateSubmission;
  final VoidCallback onNewAudit;
  final VoidCallback? onAssignTask;

  const ChecklyFab({
    super.key,
    required this.isAdmin,
    required this.canCreateSubmission,
    required this.onNewAudit,
    this.onAssignTask,
  });

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final Offset offset = button.localToGlobal(
      Offset(0, -8), // slightly above
      ancestor: overlay,
    );

    final theme = Theme.of(context);

    // 'Start New Audit' is only shown when user has submissions:create capability.
    final items = <PopupMenuEntry<String>>[
      if (canCreateSubmission)
        PopupMenuItem<String>(
          value: 'new',
          child: Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Audit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Self-performed audit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];

    if (isAdmin && onAssignTask != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'assign',
          child: Row(
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Task',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Delegate to auditor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy - (items.length * 56),
          button.size.width,
          button.size.height,
        ),
        Offset.zero & overlay.size,
      ),
      items: items,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).then((value) {
      if (value == 'new') onNewAudit();
      if (value == 'assign') onAssignTask?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the user has no actions available, hide the FAB completely.
    if (!canCreateSubmission && !(isAdmin && onAssignTask != null)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: () => _showMenu(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
