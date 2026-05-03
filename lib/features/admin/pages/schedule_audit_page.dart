import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/schedule_audit_form.dart';

/// Admin page to schedule (delegate) an audit to a specific auditor.
/// Wraps [ScheduleAuditForm] in a Scaffold.
class ScheduleAuditPage extends StatelessWidget {
  const ScheduleAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Audit')),
      body: ScheduleAuditForm(onSuccess: () => context.pop()),
    );
  }
}
