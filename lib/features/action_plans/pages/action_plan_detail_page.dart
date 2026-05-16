import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../auth/manager/auth_manager.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../model/stale_conflict.dart';
import '../widgets/action_plan_action_bar.dart';
import '../widgets/action_plan_detail_actions.dart';
import '../widgets/action_plan_detail_list.dart';

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

  void _setBusy(bool isBusy) {
    if (mounted) setState(() => _busy = isBusy);
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

        return Scaffold(
          appBar: AppBar(title: const Text('Action Plan')),
          bottomNavigationBar:
              (plan.status == 'open' || plan.status == 'pending_verify')
              ? ActionPlanActionBar(
                  plan: plan,
                  busy: _busy,
                  onSubmitEvidence: () =>
                      ActionPlanDetailActions.showSubmitEvidenceSheet(
                        context,
                        plan,
                        _manager,
                        _userName,
                      ),
                  onVerify: () => ActionPlanDetailActions.showVerifyDialog(
                    context: context,
                    plan: plan,
                    manager: _manager,
                    currentUserName: _userName,
                    setBusy: _setBusy,
                  ),
                  onReject: () => ActionPlanDetailActions.showRejectDialog(
                    context: context,
                    plan: plan,
                    manager: _manager,
                    setBusy: _setBusy,
                  ),
                )
              : null,
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
