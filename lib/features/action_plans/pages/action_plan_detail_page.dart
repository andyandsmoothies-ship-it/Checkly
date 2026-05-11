import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../model/stale_conflict.dart';
import '../widgets/action_plan_action_bar.dart';
import '../widgets/action_plan_detail_list.dart';
import '../widgets/submit_evidence_sheet.dart';

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
  StaleConflict? _staleConflict;

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();

    // Auto-fetch if not found in current cache (e.g. freshly generated on backend).
    // Uses the targeted GET /api/action-plans/{id} endpoint — avoids reloading
    // the entire plan list just to show one plan (Gotcha fix: partial inbox freeze).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exists = _manager.actionPlans.value.any(
        (p) => p.id == widget.actionPlanId,
      );
      if (!exists) {
        _manager.loadSinglePlan(widget.actionPlanId);
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
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'forbidden',
            message:
                'This action requires higher permissions. Please contact your workspace administrator.',
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
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
          body: ActionPlanDetailList(
            plan: plan,
            staleConflict: _staleConflict,
            isOverdue: isOverdue,
            onDismissConflict: () async {
              await _manager.dismissStaleConflict(_staleConflict!.id);
              _loadStaleConflict();
            },
          ),
        );
      },
    );
  }
}
