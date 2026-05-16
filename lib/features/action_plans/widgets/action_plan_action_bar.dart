import 'package:flutter/material.dart';

import 'package:checkly/_shared/constants/action_plan_actions.dart';
import '../model/action_plan_dto.dart';
import 'action_plan_action_guard.dart';

/// Role-aware action bar for the Action Plan detail page.
///
/// Encapsulates the UI logic for actionable states. The buttons are guarded
/// by [ActionPlanActionGuard] using PBAC actions provided by the server.
class ActionPlanActionBar extends StatelessWidget {
  final ActionPlanDto plan;
  final bool busy;
  final VoidCallback onSubmitEvidence;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const ActionPlanActionBar({
    super.key,
    required this.plan,
    required this.busy,
    required this.onSubmitEvidence,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (busy) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final status = plan.status;

    if (status == 'open') {
      return ActionPlanActionGuard(
        plan: plan,
        requiredAction: ActionPlanActions.submitEvidence,
        fallback: SafeArea(
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Text(
              'Waiting for Store Manager to submit evidence.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: onSubmitEvidence,
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit Evidence'),
            ),
          ),
        ),
      );
    }

    if (status == 'pending_verify') {
      return ActionPlanActionGuard(
        plan: plan,
        requiredAction: ActionPlanActions.verifyClose,
        fallback: SafeArea(
          child: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Text(
              'Awaiting Auditor Verification.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                ActionPlanActionGuard(
                  plan: plan,
                  requiredAction: ActionPlanActions.rejectEvidence,
                  child: Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Verify & Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // No action available for this role/status combo (e.g. closed plan)
    return const SizedBox.shrink();
  }
}
