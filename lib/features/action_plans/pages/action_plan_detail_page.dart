import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/unsaved_changes_guard.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../widgets/action_timeline.dart';

final _di = GetIt.instance;

/// Action Plan detail page — timeline, info, evidence, role-aware actions.
class ActionPlanDetailPage extends StatefulWidget {
  final String actionPlanId;

  const ActionPlanDetailPage({super.key, required this.actionPlanId});

  @override
  State<ActionPlanDetailPage> createState() => _ActionPlanDetailPageState();
}

class _ActionPlanDetailPageState extends State<ActionPlanDetailPage> {
  late final ActionPlanManager _manager;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();
  }

  String get _userRole => _di<AuthManager>().currentUser?.role ?? '';

  String get _userName =>
      _di<AuthManager>().currentUser?.email.split('@').first ?? 'Unknown';

  // ── Submit Evidence (Store Manager) ──
  void _showSubmitEvidenceSheet(ActionPlanDto plan) {
    final correctionCtrl = TextEditingController(text: plan.correctionPlan);
    final evidenceCtrl = TextEditingController(text: plan.evidenceNote);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var isDirty = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // Attach listeners once on first build
            void markDirty() {
              if (!isDirty) setSheetState(() => isDirty = true);
            }

            // Use addListener carefully — only attach once
            // We track via the initial text to detect changes
            final correctionChanged =
                correctionCtrl.text != (plan.correctionPlan ?? '');
            final evidenceChanged =
                evidenceCtrl.text != (plan.evidenceNote ?? '');
            final computedDirty = correctionChanged || evidenceChanged;

            return UnsavedChangesGuard(
              isDirty: isDirty || computedDirty,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  24 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Submit Evidence',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              if (isDirty || computedDirty) {
                                // Let PopScope handle via back-navigation
                                Navigator.maybePop(ctx);
                              } else {
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correctionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correction Plan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (_) => markDirty(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: evidenceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Evidence Note',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (_) => markDirty(),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _callManager(
                            () => _manager.submitEvidence(
                              plan,
                              correctionPlan: correctionCtrl.text.trim(),
                              evidenceNote: evidenceCtrl.text.trim(),
                            ),
                            successMsg:
                                'Evidence submitted — awaiting verification',
                          );
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Verify & Close (Auditor / Admin) ──
  void _showVerifyDialog(ActionPlanDto plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify & Close'),
        content: const Text(
          'Mark this action plan as resolved? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _callManager(
                () => _manager.closePlan(plan, verifierName: _userName),
                successMsg: 'Action plan closed',
              );
            },
            child: const Text('Verify & Close'),
          ),
        ],
      ),
    );
  }

  // ── Reject (Auditor / Admin) ──
  void _showRejectDialog(ActionPlanDto plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Evidence'),
        content: const Text(
          'Return this plan to open status? The store manager will '
          'need to resubmit evidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _callManager(
                () => _manager.rejectEvidence(plan),
                successMsg: 'Evidence rejected — plan reopened',
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // ── Shared manager call wrapper ──
  Future<void> _callManager(
    Future<ActionPlanDto> Function() fn, {
    required String successMsg,
  }) async {
    setState(() => _busy = true);
    try {
      await fn();
      await _manager.loadActionPlans();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } on RoleGuardException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Permission denied: $e')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build role-aware action bar ──
  Widget? _buildActionBar(ActionPlanDto plan) {
    if (_busy) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final role = _userRole;
    final status = plan.status;

    // SM can submit evidence when plan is open
    if (status == 'open' && role == 'store_manager') {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () => _showSubmitEvidenceSheet(plan),
            icon: const Icon(Icons.upload_file),
            label: const Text('Submit Evidence'),
          ),
        ),
      );
    }

    // Auditor/Admin can verify or reject when pending
    if (status == 'pending_verify' && (role == 'auditor' || role == 'admin')) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: () => _showRejectDialog(plan),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _showVerifyDialog(plan),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Verify & Close'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null; // No actions for this role/status combo
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final plan = _manager.actionPlans.value
            .cast<ActionPlanDto?>()
            .firstWhere(
              (p) => p?.id == widget.actionPlanId,
              orElse: () => null,
            );

        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Action Plan')),
            body: const Center(child: Text('Action plan not found')),
          );
        }

        final isOverdue = ActionPlanManager.isOverdue(
          plan,
          now: DateTime.now(),
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Action Plan')),
          bottomNavigationBar: _buildActionBar(plan),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Status Timeline ──
              ActionTimeline.fromStatus(plan.status),
              const SizedBox(height: 16),

              if (plan.rootCause == 'SYSTEM_VOID')
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This action plan was automatically closed because the parent audit was voided.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // ── Info Section ──
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.label,
                    label: 'Criteria',
                    value: plan.criteriaLabel,
                  ),
                  _InfoRow(
                    icon: Icons.folder,
                    label: 'Section',
                    value: plan.groupTitle,
                  ),
                  if (plan.storeName != null)
                    _InfoRow(
                      icon: Icons.store,
                      label: 'Store',
                      value: plan.storeName!,
                    ),
                  if (plan.storeManagerName != null)
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Manager',
                      value: plan.storeManagerName!,
                    ),
                  if (plan.deadline != null)
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Deadline',
                      value:
                          '${plan.deadline!.day}/${plan.deadline!.month}/${plan.deadline!.year}',
                      valueColor: isOverdue ? theme.colorScheme.error : null,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Root Cause ──
              if (plan.rootCause != null &&
                  plan.rootCause!.isNotEmpty &&
                  plan.rootCause != 'SYSTEM_VOID') ...[
                _SectionHeader(title: 'Root Cause'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      plan.rootCause!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Correction Plan ──
              if (plan.correctionPlan != null &&
                  plan.correctionPlan!.isNotEmpty) ...[
                _SectionHeader(title: 'Correction Plan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      plan.correctionPlan!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Evidence ──
              if (plan.evidenceNote != null ||
                  plan.evidencePhotoUrl != null) ...[
                _SectionHeader(title: 'Evidence'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (plan.evidenceNote != null)
                          Text(
                            plan.evidenceNote!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        if (plan.evidencePhotoUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              plan.evidencePhotoUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 100,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Verifier ──
              if (plan.verifierName != null) ...[
                _SectionHeader(title: 'Verified By'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Text(
                          plan.verifierName!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Info Card ──

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,  // Fix: was center, causing icon to float mid-block on multi-line values
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),  // Align icon cap-height with first text baseline
            child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
