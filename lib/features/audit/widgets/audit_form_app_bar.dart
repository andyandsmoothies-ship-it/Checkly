import 'package:flutter/material.dart';

import '../manager/audit_manager.dart';
import 'audit_score_hud.dart';
import 'risks_panel.dart';

/// Reusable AppBar for the Audit Form Page.
class AuditFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String templateTitle;
  final bool riskEnabled;
  final AuditManager manager;

  const AuditFormAppBar({
    super.key,
    required this.templateTitle,
    required this.riskEnabled,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(templateTitle, overflow: TextOverflow.ellipsis),
      actions: [
        // Global risks trigger
        if (riskEnabled)
          IconButton(
            icon: Icon(
              manager.triggeredRiskIds.isNotEmpty
                  ? Icons.shield
                  : Icons.shield_outlined,
              color: manager.triggeredRiskIds.isNotEmpty
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            onPressed: () => showRisksPanel(context, manager),
            tooltip: 'Critical Risks',
          ),
        // Draft saved indicator
        if (manager.draftSavedAt != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              avatar: Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'Saved',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                ),
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        AuditScoreChip(score: manager.liveScore),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
