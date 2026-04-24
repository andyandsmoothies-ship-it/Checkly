import 'package:flutter/material.dart';

import '../model/action_plan_dto.dart';

/// Role-aware action bar for the Action Plan detail page.
///
/// All branching logic (status × role × busy) is encapsulated here.
/// Callbacks are wired by the page to its existing private methods.
///
/// Returns a visible widget for actionable states; returns null-equivalent
/// (SizedBox.shrink) for states where no action is available. The PAGE
/// wraps this in its _buildActionBar() method which returns nullable
/// Widget?, returning null when this widget would show nothing.
class ActionPlanActionBar extends StatelessWidget {
  final ActionPlanDto plan;
  final bool busy;
  final bool canSubmitEvidence;
  final bool canVerify;
  final VoidCallback onSubmitEvidence;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const ActionPlanActionBar({
    super.key,
    required this.plan,
    required this.busy,
    required this.canSubmitEvidence,
    required this.canVerify,
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
      if (!canVerify) {
        if (canSubmitEvidence) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: onSubmitEvidence,
                icon: const Icon(Icons.upload_file),
                label: const Text('Submit Evidence'),
              ),
            ),
          );
        }
      } else {
        return SafeArea(
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
        );
      }
    }

    if (status == 'pending_verify') {
      if (canVerify) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    onPressed: onReject,
                    child: const Text('Reject'),
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
        );
      } else {
        return SafeArea(
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
        );
      }
    }

    // No action available for this role/status combo (e.g. closed plan)
    return const SizedBox.shrink();
  }
}
