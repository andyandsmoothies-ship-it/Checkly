import 'package:flutter/material.dart';
import '../model/action_plan_dto.dart';

/// An Action Plan scoped fail-closed wrapper.
/// Renders [child] only if [plan.allowedActions] contains [requiredAction].
/// Otherwise, renders [fallback] (defaults to SizedBox.shrink()).
/// Does not depend on global PolicyManager.
class ActionPlanActionGuard extends StatelessWidget {
  final ActionPlanDto plan;
  final String requiredAction;
  final Widget child;
  final Widget fallback;

  const ActionPlanActionGuard({
    super.key,
    required this.plan,
    required this.requiredAction,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final actions = plan.allowedActions;
    if (actions != null && actions.contains(requiredAction)) {
      return child;
    }
    return fallback;
  }
}
