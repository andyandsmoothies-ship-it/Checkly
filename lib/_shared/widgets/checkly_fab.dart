import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Speed-dial FAB matching the PWA's FloatingActionMenu.
/// Tapping the "+" opens a popup menu with role-gated actions.
///
/// **GOTCHA — Nested Scaffold:** Pages inside `_MainShell` (ShellRoute) are
/// wrapped in an outer Scaffold with `extendBody: true` and a 96px bottom nav.
/// This inner FAB MUST have `Padding(bottom: 80)` or it renders behind the
/// nav bar and becomes invisible. Do NOT remove this padding.
///
/// Refactored to use FeatherGreen fill and brand-themed popup menu styling.
class ChecklyFab extends StatelessWidget {
  final bool canAssignTask;
  final bool canCreateSubmission;
  final VoidCallback onNewAudit;
  final VoidCallback? onAssignTask;

  const ChecklyFab({
    super.key,
    required this.canAssignTask,
    required this.canCreateSubmission,
    required this.onNewAudit,
    this.onAssignTask,
  });

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final Offset offset = button.localToGlobal(
      const Offset(0, -8),
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
              const Icon(
                Icons.assignment_outlined,
                size: 20,
                color: AppColors.featherGreen,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Audit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.eel,
                    ),
                  ),
                  Text(
                    'Self-performed audit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.wolf,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];

    if (canAssignTask && onAssignTask != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'assign',
          child: Row(
            children: [
              const Icon(
                Icons.person_add_outlined,
                size: 20,
                color: AppColors.macaw,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Task',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.eel,
                    ),
                  ),
                  Text(
                    'Delegate to auditor',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.wolf,
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.swan, width: 2),
      ),
      elevation: 0,
    ).then((value) {
      if (value == 'new') onNewAudit();
      if (value == 'assign') onAssignTask?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the user has no actions available, hide the FAB completely.
    if (!canCreateSubmission && !(canAssignTask && onAssignTask != null)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: () => _showMenu(context),
        backgroundColor: AppColors.featherGreen,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
