import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../widgets/action_plan_action_bar.dart';
import '../widgets/action_timeline.dart';
import '../widgets/flat_block.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';
import '../widgets/stale_conflict_banner.dart';
import '../widgets/submit_evidence_sheet.dart';
import '../../../_shared/database/app_database.dart';

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
  PendingActionPlanUpdate? _staleConflict;

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();

    // Auto-fetch if not found in current cache (e.g. freshly generated on backend)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exists = _manager.actionPlans.value.any(
        (p) => p.id == widget.actionPlanId,
      );
      if (!exists) {
        _manager.loadActionPlans();
      }
    });

    _loadStaleConflict();
  }

  Future<void> _loadStaleConflict() async {
    final conflict = await _manager.getStaleConflict(widget.actionPlanId);
    if (mounted) {
      setState(() {
        _staleConflict = conflict;
      });
    }
  }

  String get _userName =>
      _di<AuthManager>().currentUser?.email.split('@').first ?? 'Unknown';

  // ── Submit Evidence (Store Manager) ──
  void _showSubmitEvidenceSheet(ActionPlanDto plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubmitEvidenceSheet(
        plan: plan,
        manager: _manager,
        currentUserName: _userName,
      ),
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
    } on RoleGuardException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This action requires higher permissions. Please contact your workspace administrator.',
            ),
          ),
        );
      }
    } catch (e) {
      // H2 Fix: Sanitise generic errors — never expose raw Dart exception strings
      // to users. Domain-specific RoleGuardException is handled above.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build role-aware action bar ──
  Widget? _buildActionBar(ActionPlanDto plan) {
    final status = plan.status;
    if (status != 'open' && status != 'pending_verify') return null;

    final canSubmitEvidence = _di<PolicyManager>().can(
      AppCapabilities.actionPlansWrite,
    );
    final canVerify = _di<PolicyManager>().can(
      AppCapabilities.actionPlansVerify,
    );

    // Guard: open + no role that acts → no bar
    if (status == 'open' && !canSubmitEvidence && !canVerify) return null;

    return ActionPlanActionBar(
      plan: plan,
      busy: _busy,
      canSubmitEvidence: canSubmitEvidence,
      canVerify: canVerify,
      onSubmitEvidence: () => _showSubmitEvidenceSheet(plan),
      onVerify: () => _showVerifyDialog(plan),
      onReject: () => _showRejectDialog(plan),
    );
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
          if (_manager.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Action Plan')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Action Plan')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Action plan not found'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final isOverdue = ActionPlanManager.isOverdue(
          plan,
          now: DateTime.now(),
        );

        final canSubmitEvidence = _di<PolicyManager>().can(
          AppCapabilities.actionPlansWrite,
        );
        final canVerify = _di<PolicyManager>().can(
          AppCapabilities.actionPlansVerify,
        );
        final showOverride =
            plan.status == 'open' && canSubmitEvidence && canVerify;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Action Plan'),
            actions: showOverride
                ? [
                    PopupMenuButton<String>(
                      onSelected: (_) => _showSubmitEvidenceSheet(plan),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'override',
                          child: Row(
                            children: [
                              Icon(Icons.upload_file, size: 20),
                              SizedBox(width: 12),
                              Text('Override: Submit Evidence'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          bottomNavigationBar: _buildActionBar(plan),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_staleConflict != null) ...[
                StaleConflictBanner(
                  correctionPlan: _staleConflict!.correctionPlan,
                  evidenceNote: _staleConflict!.evidenceNote,
                  onDismiss: () async {
                    await _manager.dismissStaleConflict(_staleConflict!.id);
                    _loadStaleConflict();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Status Timeline ──
              ActionTimeline.fromPlan(plan),
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
              InfoCard(
                children: [
                  InfoRow(
                    icon: Icons.label,
                    label: 'Criteria',
                    value: plan.criteriaLabel,
                  ),
                  InfoRow(
                    icon: Icons.folder,
                    label: 'Section',
                    value: plan.groupTitle,
                  ),
                  if (plan.storeName != null)
                    InfoRow(
                      icon: Icons.store,
                      label: 'Store',
                      value: plan.storeName!,
                    ),
                  if (plan.storeManagerName != null)
                    InfoRow(
                      icon: Icons.person,
                      label: 'Manager',
                      value: plan.storeManagerName!,
                    ),
                  if (plan.deadline != null)
                    InfoRow(
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
                SectionHeader(title: 'Root Cause'),
                FlatBlock(
                  child: Text(
                    plan.rootCause!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Correction Plan ──
              if (plan.correctionPlan != null &&
                  plan.correctionPlan!.isNotEmpty) ...[
                SectionHeader(title: 'Correction Plan'),
                FlatBlock(
                  child: Text(
                    plan.correctionPlan!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Evidence ──
              if (plan.evidenceNote != null ||
                  plan.evidencePhotoUrl != null) ...[
                SectionHeader(title: 'Evidence'),
                FlatBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.evidenceNote != null)
                        Text(
                          plan.evidenceNote!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      if (plan.evidencePhotoUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              !plan.evidencePhotoUrl!.startsWith('http')
                              ? Image.file(
                                  File(plan.evidencePhotoUrl!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  plan.evidencePhotoUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, s) => Container(
                                    height: 100,
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
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
                const SizedBox(height: 16),
              ],

              // ── Verifier ──
              if (plan.verifierName != null) ...[
                SectionHeader(title: 'Verified By'),
                FlatBlock(
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        plan.verifierName!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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
