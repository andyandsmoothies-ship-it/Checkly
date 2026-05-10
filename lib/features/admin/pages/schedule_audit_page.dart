import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../widgets/schedule_audit_form.dart';

/// Admin page to schedule (delegate) an audit to a specific auditor.
/// Wraps [ScheduleAuditForm] in a Scaffold.
/// Requires [AppCapabilities.submissionsCreate]. Users without this capability
/// see an access-denied view instead of the form.
class ScheduleAuditPage extends StatelessWidget {
  const ScheduleAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pm = GetIt.instance<PolicyManager>();
    final canSchedule = pm.can(AppCapabilities.submissionsCreate);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Audit')),
      body: canSchedule
          ? ScheduleAuditForm(onSuccess: () => context.pop())
          : const _AccessDeniedView(),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Access Restricted',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to schedule audits.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
